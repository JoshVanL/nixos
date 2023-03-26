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
  };

  outputs = { self, nixpkgs, home-manager, joshvanldwm }@inputs:
  let
    lib = nixpkgs.lib;

    pkgsOverlays = system: [ joshvanldwm.overlays.${system} ] ++
    lib.mapAttrsToList (name: _: import ./overlays/${name}) (lib.filterAttrs
      (name: entryType: lib.hasSuffix ".nix" name && entryType == "regular")
      (builtins.readDir ./overlays)
    );

    myPkgs = sys: {
      # propagate git revision
      system.configurationRevision = lib.mkIf (self ? rev) self.rev;
      nixpkgs = {
        overlays = (pkgsOverlays sys);
        config.packageOverrides = (import ./pkgs/default.nix);
      };
    };

    machines = system: map (lib.removeSuffix ".nix") (lib.attrNames(
      lib.filterAttrs
        (_: entryType: entryType == "regular")
        (builtins.readDir ./machines/${system})
    ));

    build-machine = machine: system: {
      name = machine;
      value = lib.makeOverridable lib.nixosSystem {
        system = system;
        modules = (import ./modules/module-list.nix) ++ [
          (myPkgs system)
          (import (./machines + "/${system}/${machine}.nix"))
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.josh = { ... }: { home.stateVersion = "22.11"; };
          }
        ];
      };
    };

  in {
    nixosConfigurations = builtins.listToAttrs (lib.flatten (
      (map
        ( machine: [ (build-machine machine "x86_64-linux") ])
        (machines "x86_64-linux"))
      ++
      (map
        ( machine: [ (build-machine machine "aarch64-linux") ])
        (machines "aarch64-linux"))
    ));
  };
}
