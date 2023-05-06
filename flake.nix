{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    joshvanldwm = {
      url = "github:joshvanl/dwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-serve-ng = {
      url = "github:aristanetworks/nix-serve-ng";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, joshvanldwm, nix-serve-ng }@inputs:
  let
    lib = nixpkgs.lib;

    pkgsOverlays = system: [ joshvanldwm.overlays.${system} ] ++
    lib.mapAttrsToList (name: _: import ./overlays/${name}) (lib.filterAttrs
      (name: entryType: lib.hasSuffix ".nix" name && entryType == "regular")
      (builtins.readDir ./overlays)
    );

    machines = system: map (lib.removeSuffix ".nix") (lib.attrNames(
      lib.filterAttrs
        (_: entryType: entryType == "regular")
        (builtins.readDir ./machines/${system})
    ));

    build-machine = machine: system: {
      name = machine;
      value = lib.makeOverridable lib.nixosSystem {
        system = system;
        modules = [
          ({ pkgs, lib, config, ... }: {
            nixpkgs.config.packageOverrides = (import ./pkgs/default.nix);
            nixpkgs.overlays = pkgsOverlays system;
            system.configurationRevision = lib.mkIf (self ? rev) self.rev;
            imports = (import ./modules/module-list.nix) ++ [
              (import (./machines/${system}/${machine}.nix))
            ];
          })
          nix-serve-ng.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };

  in {
    nixosConfigurations = builtins.listToAttrs (lib.flatten (
      (map ( machine: [ (build-machine machine "x86_64-linux") ])
        (machines "x86_64-linux"))
      ++
      (map ( machine: [ (build-machine machine "aarch64-linux") ])
        (machines "aarch64-linux"))
    ));
  };
}
