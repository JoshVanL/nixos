printHelp() {
  echo "Usage: update [<specialisation>]"
}

if [ $# -gt 1 ]; then
    printHelp
    exit 1
fi

SPEC=""

if [ $# -eq 0 ]; then
  CURRENT_SPEC="$(specialisation -q)"
  if [ "$CURRENT_SPEC" != "main" ]; then
    SPEC="--specialisation $CURRENT_SPEC"
  fi
elif [ "$1" != "main" ]; then
  SPEC="--specialisation $1"
fi

cmd="sudo nixos-rebuild switch -L --flake '/keep/etc/nixos/.#' $SPEC"
eval "$cmd"
