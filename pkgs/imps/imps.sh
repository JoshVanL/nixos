CURDIR=$(pwd)
TMPDIR=$(mktemp -d)

_imps_cleanup() {
  cd "$CURDIR"
  rm -rf "$TMPDIR"
}

trap '_imps_cleanup' EXIT

echo ">> Importing resident key reference from YubiKey..."
cd "$TMPDIR"
ssh-keygen -K

echo ">> Resident key reference imported!"

SSHDIR="$HOME/.ssh"
mkdir -p "$SSHDIR"
for file in *; do
  NEWFILE="$SSHDIR/${file%_rk}"
  echo ">> Moving '$file' to '$NEWFILE'"
  mv "$file" "$NEWFILE"
done

echo ">> Success!"
