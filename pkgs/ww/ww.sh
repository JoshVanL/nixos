if [ $# -ne 1 ]; then
  echo "Usage: ww <command>"
  exit 1
fi

if ! which "$@" > /dev/null 2>&1; then
  echo "Command not found: $*"
  exit 1
fi

WHERE=$(whereis "$@")
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "$WHERE"
  exit $EXIT_CODE
fi
readlink -f "$(echo "$WHERE" | awk '{print $NF}')"
