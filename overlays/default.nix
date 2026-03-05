{ lib, inputs }:
with lib;
let
  overlays = mapAttrs (_: file: import ./${file}) (nixFilesNoDefault ./.);

  # golang overlay needs nixpkgs-unstable for go_1_26
  golangOverlay = import ./golang.nix { inherit inputs; };

in {
  modules = {
    nixpkgs.overlays = (attrValues (removeAttrs overlays ["golang"])) ++ [ golangOverlay ];
  };
  overlays = overlays // { golang = golangOverlay; };
}
