{ lib }:
with lib;
let
  overlays = mapAttrs (_: file: import ./${file}) (nixFilesNoDefault ./.);

in {
  modules = {
    nixpkgs.overlays = attrValues overlays;
  };
  inherit overlays;
}
