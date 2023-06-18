{ lib }:
with lib;
let
  files = nixFilesNoDefault' ./.;
  toMachine = file: (import ./${file} {config={};pkgs={};lib=lib;});

in mapAttrs' (_: file: nameValuePair
  ((toMachine file).me.machineName)
  {
    modules = (import ./${file});
    system = (toMachine file).me.system;
  }
) files
