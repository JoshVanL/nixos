{
writeShellApplication,
stdenv,
installShellFiles,
mermaid-ascii,
mermaid-cli,
chafa,
coreutils,
feh,
gawk,
}:

let
  sh = writeShellApplication {
    name = "mmd";
    runtimeInputs = [ mermaid-ascii mermaid-cli chafa coreutils feh gawk ];
    text = builtins.readFile ./mmd.sh;
  };

  mmd = stdenv.mkDerivation {
    name = "mmd";
    src = sh;
    nativeBuildInputs = [ installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/mmd $out/bin
      installShellCompletion --cmd mmd --zsh ${./completion.zsh}
    '';
  };

in mmd
