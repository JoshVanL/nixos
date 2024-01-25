printHelp() {
  echo "Usage: gimmi <packages>"
}

if [ $# -eq 0 ]; then
    printHelp
    exit 1
fi

PKGS=()
for pkg in "$@"; do
  if [[ "$pkg" == -* ]]; then
    break
  fi
  PKGS+=("nixpkgs#$pkg")
done

CMD="nix shell ${PKGS[*]}"
eval "$CMD"
