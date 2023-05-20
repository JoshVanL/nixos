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

    machines = map (lib.removeSuffix ".nix") (lib.attrNames(
      lib.filterAttrs
        (_: entryType: entryType == "regular")
        (builtins.readDir ./machines)
    ));

    build = name: system: {
      inherit name;
      value = lib.makeOverridable lib.nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, lib, config, ... }: {
            nixpkgs.config.packageOverrides = (import ./pkgs/default.nix);
            nixpkgs.overlays = pkgsOverlays system;
            system.configurationRevision = lib.mkIf (self ? rev) self.rev;
            imports = (import ./modules/module-list.nix) ++ [
              (import (./machines/${name}.nix))
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

    buildFromName = name:
      build name (import ./machines/${name}.nix {config={};pkgs={};lib=lib;}).me.base.hardware.system;

  in {
    nixosConfigurations = builtins.listToAttrs (map buildFromName machines);
  };
}
