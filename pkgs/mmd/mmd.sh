usage() {
  echo "usage: mmd [-g] <file.mmd|file.md>" >&2
  echo "  -g  render full-fidelity images and open them in feh" >&2
  exit 1
}

graphics=false
if [ "${1:-}" = "-g" ]; then
  graphics=true
  shift
fi
[ $# -ge 1 ] || usage

in=$1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Markdown files may hold many mermaid blocks; extract each. Anything else
# is treated as a single mermaid diagram.
case "$in" in
  *.md|*.mdx|*.markdown)
    awk -v out="$tmp/block-" '
      /^[[:space:]]*```mermaid[[:space:]]*$/ { inblock = 1; n++; next }
      inblock && /^[[:space:]]*```[[:space:]]*$/ { inblock = 0; next }
      inblock { print > (out sprintf("%03d", n) ".mmd") }
    ' "$in"
    ;;
  *)
    cp "$in" "$tmp/block-001.mmd"
    ;;
esac

if [ "$graphics" = true ]; then
  # Render every block with mmdc and view the lot in one feh session.
  n=0
  for b in "$tmp"/block-*.mmd; do
    [ -e "$b" ] || continue
    n=$((n + 1))
    mmdc -i "$b" -o "$tmp/diagram-$(printf '%03d' $n).png" \
      -b '#1c1c1c' -t dark --scale 4 --quiet >/dev/null
  done
  if [ "$n" -eq 0 ]; then
    echo "no mermaid diagrams found in $in" >&2
    exit 1
  fi
  feh --scale-down --auto-zoom "$tmp"/diagram-*.png
  exit 0
fi

found=false
for b in "$tmp"/block-*.mmd; do
  [ -e "$b" ] || continue
  found=true
  # mermaid-ascii draws crisp text diagrams but only supports some types
  # (flowcharts, sequence). For the rest, render the mmdc bitmap as
  # character art with chafa.
  # It also lacks the 'actor' keyword; a participant draws the same box,
  # so rewrite it. The pristine block still goes to the mmdc fallback.
  sed 's/^\( *\)actor /\1participant /' "$b" > "$b.ascii"
  # Compact layout: tight boxes and short arrows (flowcharts only;
  # sequence diagrams render the same regardless).
  if out=$(mermaid-ascii -p 0 -x 3 -y 3 -f "$b.ascii" 2>/dev/null); then
    printf '%s\n' "$out"
  else
    mmdc -i "$b" -o "$tmp/img.png" -b transparent -t dark --scale 4 --quiet >/dev/null
    chafa -w 9 "$tmp/img.png"
    rm -f "$tmp"/img*.png
  fi
  echo
done

if [ "$found" = false ]; then
  echo "no mermaid diagrams found in $in" >&2
  exit 1
fi
