{
writeShellApplication,
systemd
}:

let
  fehr = writeShellApplication {
    name = "fehr";
    runtimeInputs = [ systemd ];
    text = builtins.readFile ./fehr.sh;
  };

in fehr
