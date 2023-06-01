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
    xpropdate = {
      url = "github:joshvanl/xpropdate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self
    , nixpkgs
    , home-manager
    , joshvanldwm
    , nix-serve-ng
    , xpropdate
  }@inputs:
  let
    lib = nixpkgs.lib;

    pkgsOverlays = system: [
      joshvanldwm.overlays.${system}
      xpropdate.overlays.${system}
    ] ++ lib.mapAttrsToList (name: _: import ./overlays/${name}) (lib.filterAttrs
      (name: entryType: lib.hasSuffix ".nix" name && entryType == "regular")
      (builtins.readDir ./overlays)
    );

    machines = map (lib.removeSuffix ".nix") (lib.attrNames(
      lib.filterAttrs
        (_: entryType: entryType == "regular")
        (builtins.readDir ./machines)
    ));

    buildMachine = name: system:
      lib.nameValuePair name (lib.makeOverridable lib.nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, lib, config, ... }: {
            nixpkgs.config.packageOverrides = (import ./pkgs);
            nixpkgs.overlays = (pkgsOverlays system);
            system.configurationRevision = lib.mkIf (self ? rev) self.rev;
            imports = (import ./modules) ++ [(import (./machines/${name}.nix))];
          })
          nix-serve-ng.nixosModules.default
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      }
    );

    sysFromMachineName = name:
      (import ./machines/${name}.nix {config={};pkgs={};lib=lib;}).me.system;

    buildFromName = name: buildMachine name (sysFromMachineName name);

  in rec {
    nixosConfigurations = builtins.listToAttrs (map buildFromName machines);
    apps = (import ./apps { inherit self nixpkgs nixosConfigurations; });
  };
}
