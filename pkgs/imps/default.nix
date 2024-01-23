{
writeShellApplication,
openssh,
}:

let
  imps = writeShellApplication {
    name = "imps";
    runtimeInputs = [ openssh ];
    text = builtins.readFile ./imps.sh;
  };

in imps
