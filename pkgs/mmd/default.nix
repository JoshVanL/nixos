{
writeShellApplication,
stdenv,
installShellFiles,
mermaid-cli,
chafa,
coreutils,
}:

let
  sh = writeShellApplication {
    name = "mmd";
    runtimeInputs = [ mermaid-cli chafa coreutils ];
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
