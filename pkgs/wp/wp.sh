set -euo pipefail

QUEUE="${WP_QUEUE:-/keep/etc/wallpapers/queue}"
LIBRARY="${WP_LIBRARY:-/keep/etc/wallpapers/library}"
BLACKLIST="${WP_BLACKLIST:-/persist/etc/wallpapers/blacklist}"

WP_QUERY="${WP_QUERY:-landscape}"
WP_CATEGORIES="${WP_CATEGORIES:-100}"
WP_PURITY="${WP_PURITY:-100}"
WP_ATLEAST="${WP_ATLEAST:-2560x1440}"
WP_SORTING="${WP_SORTING:-toplist}"
WP_TOPRANGE="${WP_TOPRANGE:-1M}"
WP_LIBRARY_MAX="${WP_LIBRARY_MAX:-200}"
WP_FETCH_COUNT="${WP_FETCH_COUNT:-12}"

mkdir -p "$QUEUE" "$LIBRARY" "$(dirname "$BLACKLIST")"
touch "$BLACKLIST"

cmd_fetch() {
  local want="${1:-$WP_FETCH_COUNT}"
  local api="https://wallhaven.cc/api/v1/search"
  local params="q=${WP_QUERY}&categories=${WP_CATEGORIES}&purity=${WP_PURITY}&atleast=${WP_ATLEAST}&sorting=${WP_SORTING}&topRange=${WP_TOPRANGE}"

  echo "fetching up to $want candidates from wallhaven (q=$WP_QUERY)"

  local seen
  seen=$(mktemp)
  trap 'rm -f "$seen"' RETURN
  cat "$BLACKLIST" > "$seen"
  find "$LIBRARY" "$QUEUE" -maxdepth 1 -type f -exec sha256sum {} + 2>/dev/null \
    | awk '{print $1}' >> "$seen"

  local got=0 page=1 considered=0
  while [ "$got" -lt "$want" ] && [ "$page" -le 5 ]; do
    echo "  [page $page] querying wallhaven..."
    local resp urls
    if ! resp=$(curl -fsSL --max-time 30 "${api}?${params}&page=${page}"); then
      echo "  wallhaven request failed (page $page)" >&2
      break
    fi
    urls=$(printf '%s' "$resp" | jq -r '.data[].path')
    if [ -z "$urls" ]; then
      echo "  [page $page] no results"
      break
    fi

    while IFS= read -r url; do
      [ "$got" -ge "$want" ] && break
      considered=$((considered+1))
      local fname ext tmp hash
      fname=$(basename "$url")
      ext="${fname##*.}"
      tmp=$(mktemp --suffix=".$ext")
      printf '  [%d] %s ... ' "$considered" "$fname"
      if ! curl -fsSL --max-time 45 -o "$tmp" "$url"; then
        echo "download failed"
        rm -f "$tmp"; continue
      fi
      hash=$(sha256sum "$tmp" | awk '{print $1}')
      if grep -qxF "$hash" "$seen"; then
        echo "duplicate, skipping"
        rm -f "$tmp"; continue
      fi
      mv "$tmp" "$QUEUE/$fname"
      echo "$hash" >> "$seen"
      got=$((got+1))
      echo "kept ($got/$want)"
    done <<< "$urls"
    page=$((page+1))
  done
  echo "added $got to queue (considered $considered candidates)"
}

cmd_refresh() {
  shopt -s nullglob
  local items=("$QUEUE"/*)
  if [ "${#items[@]}" -eq 0 ]; then
    echo "queue empty - fetching..."
    cmd_fetch
    items=("$QUEUE"/*)
    if [ "${#items[@]}" -eq 0 ]; then
      echo "nothing new (all candidates already in library or blacklist)"
      return 0
    fi
  fi

  local workdir
  workdir=$(mktemp -d)
  trap 'rm -rf "$workdir"' EXIT
  : > "$workdir/keep"
  : > "$workdir/skip"

  feh \
    --fullscreen \
    --auto-zoom \
    --hide-pointer \
    --title "wp refresh [%u/%l] %f  |  1=keep  2=skip  q=quit" \
    --action1 ";echo %f >> $workdir/keep; xdotool key --clearmodifiers Right" \
    --action2 ";echo %f >> $workdir/skip; xdotool key --clearmodifiers Right" \
    "${items[@]}" || true

  local kept=0 skipped=0
  if [ -s "$workdir/keep" ]; then
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      mv -n "$f" "$LIBRARY/" && kept=$((kept+1)) || true
    done < <(sort -u "$workdir/keep")
  fi
  if [ -s "$workdir/skip" ]; then
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      sha256sum "$f" | awk '{print $1}' >> "$BLACKLIST"
      rm -f "$f"
      skipped=$((skipped+1))
    done < <(sort -u "$workdir/skip")
  fi
  echo "kept $kept, skipped $skipped"
  cmd_prune
}

cmd_view() {
  shopt -s nullglob
  local items=("$LIBRARY"/*)
  if [ "${#items[@]}" -eq 0 ]; then
    echo "library empty"
    return 0
  fi
  feh \
    --fullscreen \
    --auto-zoom \
    --hide-pointer \
    --title "wp view [%u/%l] %f  |  arrows=navigate  q=quit" \
    "${items[@]}"
}

cmd_rotate() {
  shopt -s nullglob
  local items=("$LIBRARY"/*)
  if [ "${#items[@]}" -eq 0 ]; then
    echo "library empty - run 'wp fetch' then 'wp review'"
    return 0
  fi
  feh --no-fehbg --bg-scale --randomize "$LIBRARY"
}

cmd_roll() {
  systemctl restart --user feh.service
}

cmd_prune() {
  local count
  count=$(find "$LIBRARY" -maxdepth 1 -type f | wc -l)
  if [ "$count" -gt "$WP_LIBRARY_MAX" ]; then
    local overage=$((count - WP_LIBRARY_MAX))
    echo "pruning $overage oldest from library"
    find "$LIBRARY" -maxdepth 1 -type f -printf '%T@\t%p\n' \
      | sort -n \
      | head -n "$overage" \
      | cut -f2- \
      | xargs -r rm -f
  fi
}

cmd_ls() {
  local lc qc bc
  lc=$(find "$LIBRARY" -maxdepth 1 -type f 2>/dev/null | wc -l)
  qc=$(find "$QUEUE" -maxdepth 1 -type f 2>/dev/null | wc -l)
  bc=$(wc -l < "$BLACKLIST" 2>/dev/null || echo 0)
  printf 'library:    %s / %s  (%s)\n' "$lc" "$WP_LIBRARY_MAX" "$LIBRARY"
  printf 'queue:      %s  (%s)\n' "$qc" "$QUEUE"
  printf 'blacklist:  %s  (%s)\n' "$bc" "$BLACKLIST"
}

usage() {
  cat <<EOF
wp - wallpaper queue/library manager

  wp fetch [N]   pull N candidates from wallhaven into queue (default $WP_FETCH_COUNT).
                 Dedupes against library + blacklist. Prints per-candidate progress.
  wp refresh     walk new candidates in feh and prune library afterwards.
                 Auto-fetches if queue is empty.
                   1 = keep (move to library, auto-advance)
                   2 = skip (record hash to blacklist, auto-advance)
                   arrows = navigate manually
                   q = quit; actions apply on exit
  wp view        browse the library in feh (read-only, arrows to navigate, q to quit)
  wp roll        rotate to a new wallpaper now (restarts feh.service)
  wp rotate      apply a random wallpaper from library (used by feh.service;
                 no-op on empty library)
  wp ls          show library/queue/blacklist counts and paths (default)
  wp prune       trim library to \$WP_LIBRARY_MAX, oldest first

env vars (override defaults):
  WP_QUEUE         $QUEUE
  WP_LIBRARY       $LIBRARY
  WP_BLACKLIST     $BLACKLIST
  WP_QUERY         $WP_QUERY
  WP_CATEGORIES    $WP_CATEGORIES   (bitmask: General/Anime/People)
  WP_PURITY        $WP_PURITY   (bitmask: SFW/Sketchy/NSFW)
  WP_ATLEAST       $WP_ATLEAST
  WP_SORTING       $WP_SORTING   (toplist|date_added|views|favorites|random|relevance)
  WP_TOPRANGE      $WP_TOPRANGE     (1d|3d|1w|1M|3M|6M|1y, used when sorting=toplist)
  WP_LIBRARY_MAX   $WP_LIBRARY_MAX
  WP_FETCH_COUNT   $WP_FETCH_COUNT
EOF
}

case "${1:-}" in
  fetch)        shift; cmd_fetch "$@" ;;
  refresh)      cmd_refresh ;;
  view)         cmd_view ;;
  roll)         cmd_roll ;;
  rotate)       cmd_rotate ;;
  prune)        cmd_prune ;;
  ls|"")        cmd_ls ;;
  -h|--help)    usage ;;
  *)            echo "unknown command: $1" >&2; usage; exit 1 ;;
esac
