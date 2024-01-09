{
pkgs,
lib,
writeTextFile,
writeShellApplication,
nix,
stdenv,
installShellFiles,
}:

let
  completionZSH = writeTextFile {
    name = "completion.zsh";
    text = with lib; ''
      #compdef _gimmi gimmi

      function _gimmi() {
        _arguments -C "1:pkgs:_pkgs"
      }

      function _pkgs() {
        local -a pkgs
        pkgs=( ${builtins.replaceStrings ["'"] ["\\'"] (concatStringsSep " " (attrNames pkgs))} )

        _wanted pkgs expl 'packages' compadd -a pkgs
      }
    '';
  };

  sh = writeShellApplication {
    name = "gimmi";
    runtimeInputs = [ nix ];
    text = builtins.readFile ./gimmi.sh;
  };

  gimmi = stdenv.mkDerivation {
    name = "gimmi";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      installShellCompletion --cmd gimmi --zsh ${completionZSH}
    '';
  };

in gimmi
