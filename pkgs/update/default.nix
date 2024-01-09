{
writeShellApplication,
nixos-rebuild,
specialisation,
stdenv,
installShellFiles,
}:

with builtins;
let
  sh = writeShellApplication {
    name = "update";
    runtimeInputs = [
      nixos-rebuild
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
