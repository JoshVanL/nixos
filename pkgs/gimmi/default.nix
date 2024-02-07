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
  allPackages = replaceStrings ["'"] ["\\'"] (concatStringsSep " " (attrNames pkgs));

  completionZSH = writeTextFile {
    name = "completion.zsh";
    text = with lib; ''
      #compdef gimmi

      local -a pkgs
      pkgs=( ${allPackages} )

      function _pkgs() {
        _wanted pkgs expl 'packages' compadd -a pkgs
      }

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
