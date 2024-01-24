{
writeShellApplication,
curl,
}:

let
  myip = writeShellApplication {
    name = "myip";
    runtimeInputs = [ curl ];
    text = builtins.readFile ./myip.sh;
  };

in myip
