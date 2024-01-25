printHelp() {
  echo "Usage: gimmi <packages>"
}

if [ $# -eq 0 ]; then
    printHelp
    exit 1
fi

nix-shell -p "$@" --run "$SHELL"
