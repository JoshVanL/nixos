{
writeShellApplication,
stdenv,
curl,
}:

let
  sh = writeShellApplication {
    name = "binday";
    text = builtins.readFile ./binday.sh;
  };

  binday = stdenv.mkDerivation {
    name = "binday";
    src = sh;
    runtimeInputs = [ curl ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/binday $out/bin
    '';
  };

in binday
