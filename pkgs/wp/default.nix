{
writeShellApplication,
stdenv,
installShellFiles,
curl,
jq,
feh,
xdotool,
coreutils,
findutils,
gawk,
gnugrep,
util-linux,
systemd,
}:

let
  sh = writeShellApplication {
    name = "wp";
    runtimeInputs = [
      curl
      jq
      feh
      xdotool
      coreutils
      findutils
      gawk
      gnugrep
      util-linux
      systemd
    ];
    text = builtins.readFile ./wp.sh;
  };

  wp = stdenv.mkDerivation {
    name = "wp";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/wp $out/bin
      installShellCompletion --cmd wp --zsh ${./completion.zsh}
    '';
  };

in wp
