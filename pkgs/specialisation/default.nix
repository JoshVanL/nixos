{
lib,
stdenv,
writeShellApplication,
installShellFiles,
}:

with builtins;
let
  currentSH = writeShellApplication {
    name = "current-specialisation";
    text = readFile ./current-specialisation.sh;
  };

  sh = writeShellApplication {
    name = "specialisation";
    runtimeInputs = [
      installShellFiles
      currentSH
    ];
    text = readFile ./specialisation.sh;
  };

  specialisation = stdenv.mkDerivation {
    name = "specialisation";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      installShellCompletion --cmd specialisation --zsh ${./completion.zsh}
    '';
  };

in specialisation
