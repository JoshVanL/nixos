printHelp() {
  echo "Usage: gimmi <package>"
}

if [ $# -ne 1 ]; then
    printHelp
    exit 1
fi

nix-shell -p "$@" --run "$SHELL"
