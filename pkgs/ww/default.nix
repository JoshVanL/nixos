{
writeShellApplication,
stdenv,
installShellFiles,
}:

let
  wwSH = writeShellApplication {
    name = "ww";
    text = builtins.readFile ./ww.sh;
  };

  ww = stdenv.mkDerivation {
    name = "ww";
    src = wwSH;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/ww $out/bin
      installShellCompletion --cmd ww --zsh ${./completion.zsh}
    '';
  };

in ww
