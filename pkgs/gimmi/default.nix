{
pkgs,
lib,
writeTextFile,
writeShellApplication,
nix,
stdenv,
installShellFiles,
}:

with builtins;
let
  completionZSH = writeTextFile {
    name = "completion.zsh";
    text = with lib; ''
      #compdef _gimmi gimmi

      function _gimmi() {
        _arguments -C \
          "1:pkgs:_pkgs" \
          "2:pkgs:_pkgs" \
          "3:pkgs:_pkgs" \
          "4:pkgs:_pkgs" \
          "5:pkgs:_pkgs" \
          "6:pkgs:_pkgs" \
          "7:pkgs:_pkgs" \
          "8:pkgs:_pkgs" \
          "9:pkgs:_pkgs" \
          "10:pkgs:_pkgs"
      }

      function _pkgs() {
        local -a pkgs
        pkgs=( ${replaceStrings ["'"] ["\\'"] (concatStringsSep " " (attrNames pkgs))} )

        _wanted pkgs expl 'packages' compadd -a pkgs
      }
    '';
  };

  sh = writeShellApplication {
    name = "gimmi";
    runtimeInputs = [ nix ];
    text = readFile ./gimmi.sh;
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
