{ lib, nixpkgs }:
with lib;
let
  pkgsys = system: import nixpkgs { inherit system; };

  callPackages = pkgs: listToAttrs (map (name:
      nameValuePair name (pkgs.callPackage (./${name}) {})
    ) (dirs ./.));

  output = listToAttrs (map (system:
      nameValuePair system (callPackages (pkgsys system))
  ) targetSystems);

in {
  inherit output;
  modules = { pkgs, ... }: {
    nixpkgs.config.packageOverrides = (callPackages pkgs);
  };
}
