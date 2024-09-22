CMD_NAME=$(basename "${0}")
PASSENC_EXTRA_FLAGS=${PASSENC_EXTRA_FLAGS:-}

printHelp() {
  echo "Usage: ${CMD_NAME} <input file> <output file>"
  echo "       ${CMD_NAME} [-h]"
  echo "${PASSENC_HELP_TEXT}"
  echo "Use '${PASSENC_OTHER_CMD_NAME}' to ${PASSENC_ACTION} the file."
  echo "Passwords must be at least ${PASSENC_MIN_PASS_LENGTH} characters."
}

while getopts 'h' OPTION; do
  case "$OPTION" in
    h)
      printHelp
      exit 0
      ;;
    *)
      echo "Invalid input."
      printHelp
      exit 1
      ;;
  esac
done

if [ $# -ne 2 ]; then
  echo "Invalid number of arguments ($#), expecting 2."
  printHelp
  exit 1
fi

if [ "${1}" == "${2}" ]; then
    echo "Cannot ${PASSENC_ACTION} file '${1}' to itself."
    exit 1
fi

if [ ! -f "${1}" ]; then
    echo "Cannot ${PASSENC_ACTION} file '${1}' as it does not exist."
    exit 1
fi

if [ -f "${2}" ]; then
    echo "Cannot ${PASSENC_ACTION} file '${1}' to '${2}' as '${2}' already exists."
    exit 1
fi

read -r -p "Password to ${PASSENC_ACTION}: " -s PASSWORD
echo ""

if [ ${#PASSWORD} -lt "${PASSENC_MIN_PASS_LENGTH}" ]; then
    echo "Password must be at least ${PASSENC_MIN_PASS_LENGTH} characters, got ${#PASSWORD}."
    exit 1
fi

echo "Doing ${PASSENC_ACTION} with AES-256-CBC and PBKDF2 with '${PASSENC_ITERATIONS}' iterations from '${1}' to '${2}'..."
CMD="openssl enc -aes-256-cbc -pbkdf2 -iter ${PASSENC_ITERATIONS} -k ${PASSWORD} -out ${2} ${PASSENC_EXTRA_FLAGS} < ${1}"
eval "${CMD}"
