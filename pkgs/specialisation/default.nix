{
lib,
stdenv,
writeShellApplication,
installShellFiles,
}:

let
  currentSpecSH = writeShellApplication {
    name = "current-specialisation";
    text = builtins.readFile ./current-specialisation.sh;
  };

  specialisationSH = writeShellApplication {
    name = "specialisation";
    runtimeInputs = [
      installShellFiles
      currentSpecSH
    ];
    text = builtins.readFile ./specialisation.sh;
  };

  specialisation = stdenv.mkDerivation {
    name = "specialisation";
    src = specialisationSH;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/specialisation $out/bin
      installShellCompletion --cmd specialisation --zsh ${./completion.zsh}
    '';
  };

in specialisation
