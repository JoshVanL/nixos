{
writeShellApplication,
stdenv,
installShellFiles,
}:

let
  sh = writeShellApplication {
    name = "ww";
    text = builtins.readFile ./ww.sh;
  };

  ww = stdenv.mkDerivation {
    name = "ww";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/ww $out/bin
      installShellCompletion --cmd ww --zsh ${./completion.zsh}
    '';
  };

in ww
