if [ $# -lt 1 ]; then
  echo "usage: mmd <file.mmd|file.md>" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mmdc -i "$1" -o "$tmp/out.png" -b transparent -t dark --scale 2 --quiet >/dev/null

found=false
for f in "$tmp"/*.png; do
  [ -e "$f" ] || continue
  found=true
  chafa "$f"
done

if [ "$found" = false ]; then
  echo "no mermaid diagrams found in $1" >&2
  exit 1
fi
