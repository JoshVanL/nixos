{ lib }:
with lib;
let
  files = filterAttrs (name: _: name != "default.nix") (lib.nixFiles ./.);
  machine = file: (import ./${file} {config={};pkgs={};lib=lib;});

in mapAttrs' (file: _: nameValuePair
  ((machine file).me.machineName)
  {
    system = (machine file).me.system;
    modules = [ (import ./${file}) ];
  }
) files
