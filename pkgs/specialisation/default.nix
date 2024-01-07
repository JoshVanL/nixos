{
writeShellApplication,
lib,
}:

let
  currentSpecialisationSH = writeShellApplication {
    name = "current-specialisation";
    text = ''
      CURRENT_SPEC="main"
      CURRENT_SPEC_DIR=$(readlink /run/current-system)
      for f in /nix/var/nix/profiles/system/specialisation/*; do
        if [ "$(readlink "$f")" = "$CURRENT_SPEC_DIR" ]; then
          CURRENT_SPEC=$(basename "$f")
          break
        fi
      done
      echo "$CURRENT_SPEC"
    '';
  };

in writeShellApplication {
  name = "specialisation";
  runtimeInputs = [ currentSpecialisationSH ];
  text = ''
    mapfile -t SPECIALISATIONS < <(ls /nix/var/nix/profiles/system/specialisation)
    SPECIALISATIONS=( "main" "''${SPECIALISATIONS[@]}" )

    containsSpec() {
      local e match="$1"
      shift
      for e; do [[ "$e" == "$match" ]] && return 0; done
      return 1
    }

    printHelp() {
      echo "Usage: specialisation <name>"
      echo "       specialisation [-q | -h]"
      echo "Names: ''${SPECIALISATIONS[*]}"
      echo "Current: ''${CURRENT_SPEC}"
    }

    CURRENT_SPEC="$(current-specialisation)"

    while getopts 'qh' OPTION; do
      case "$OPTION" in
        q)
          echo "$CURRENT_SPEC"
          exit 0
          ;;
        h)
          printHelp
          exit 0
          ;;
        *)
          printHelp
          exit 1
          ;;
      esac
    done

    if [ $# -ne 1 ]; then
        printHelp
        exit 1
    fi
    if ! containsSpec "$1" "''${SPECIALISATIONS[@]}"; then
      echo "Specialisation '$1' does not exist."
      exit 1
    fi
    if [ "$1" = "main" ]; then
        echo "Switching from '$CURRENT_SPEC' to 'main' configuration."
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    else
        echo "Switching from '$CURRENT_SPEC' to specialisation '$1'."
        sudo /nix/var/nix/profiles/system/specialisation/"$1"/bin/switch-to-configuration switch
    fi

    if [ -f "$HOME/.config/specialisation/post-command.sh" ]; then
      exec "$HOME/.config/specialisation/post-command.sh"
    fi
  '';
}
