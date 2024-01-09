CURRENT_SPEC="main"
CURRENT_SPEC_DIR=$(readlink /run/current-system)
for f in /nix/var/nix/profiles/system/specialisation/*; do
  if [ "$(readlink "$f")" = "$CURRENT_SPEC_DIR" ]; then
    CURRENT_SPEC=$(basename "$f")
    break
  fi
done
echo "$CURRENT_SPEC"
