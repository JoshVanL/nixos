{ writeShellApplication
, coreutils
}:

writeShellApplication {
  name = "ww";
  runtimeInputs = [ coreutils ];
  text = ''
    WHERE=$(whereis "$@")
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "$WHERE"
      exit $EXIT_CODE
    fi
    readlink -f "$(echo "$WHERE" | awk '{print $2}')"
  '';
}