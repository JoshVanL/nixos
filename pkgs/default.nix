{ lib, nixpkgs, inputs }:
with lib;
let
  pkgsys = system: import nixpkgs { inherit system; };

  # Packages that take an `inputs` argument get the flake inputs.
  callPackages = pkgs: listToAttrs (map (name:
      nameValuePair name (pkgs.callPackage (./${name})
        (optionalAttrs (functionArgs (import ./${name}) ? inputs) { inherit inputs; }))
    ) (dirs ./.));

  packages = listToAttrs (map (system:
      nameValuePair system (callPackages (pkgsys system))
  ) targetSystems);

in {
  inherit packages;
  modules = { pkgs, ... }: {
    nixpkgs.config.packageOverrides = (callPackages pkgs);
  };
}
