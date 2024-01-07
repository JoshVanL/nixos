{
lib,
stdenv,
writeShellApplication,
installShellFiles,
}:

let
  currentSpecSH = writeShellApplication {
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

  specSH = writeShellApplication {
    name = "specialisation";
    runtimeInputs = [
      installShellFiles
      currentSpecSH
    ];
    text = builtins.readFile ./specialisation.sh;
  };

  specDer = stdenv.mkDerivation {
    name = "specialisation";
    src = specSH;
    buildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/specialisation $out/bin
      installShellCompletion --cmd specialisation --zsh ${./completion.zsh}
    '';
  };

in specDer
