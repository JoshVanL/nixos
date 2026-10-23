{
callPackage,
writeShellApplication,
stdenv,
installShellFiles,
}:

with builtins;
let
  specialisation = callPackage ../specialisation {};

  sh = writeShellApplication {
    name = "update";
    runtimeInputs = [
      specialisation
    ];
    text = readFile ./update.sh;
  };

  update = stdenv.mkDerivation {
    name = "update";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      installShellCompletion --cmd update --zsh ${./completion.zsh}
    '';
  };

in update
