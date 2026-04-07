{ lib, inputs }:
with lib;
let
  overlays = mapAttrs (_: file: import ./${file}) (nixFilesNoDefault ./.);

  # These overlays need nixpkgs-unstable for newer Go
  golangOverlay = import ./golang.nix { inherit inputs; };
  daprOverlay = import ./dapr.nix { inherit inputs; };

in {
  modules = {
    nixpkgs.overlays = (attrValues (removeAttrs overlays ["golang" "dapr"])) ++ [ golangOverlay daprOverlay ];
  };
  overlays = overlays // { golang = golangOverlay; dapr = daprOverlay; };
}
