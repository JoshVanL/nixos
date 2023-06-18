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
    lib = nixpkgs.lib // {
      nixFiles = dir: lib.filterAttrs (name: _: lib.hasSuffix ".nix" name) (builtins.readDir dir);
    };

    pkgsOverlays = system: [
      joshvanldwm.overlays.${system}
      xpropdate.overlays.${system}
    ] ++ lib.mapAttrsToList (name: _: import ./overlays/${name}) (lib.nixFiles ./overlays);

    machines = (import ./machines {inherit lib;});

    buildMachine = name: machine: lib.makeOverridable lib.nixosSystem {
      system = machine.system;
      modules = [
        ({ pkgs, lib, config, ... }: {
          nixpkgs.config.packageOverrides = (import ./pkgs);
          nixpkgs.overlays = (pkgsOverlays machine.system);
          system.configurationRevision = lib.mkIf (self ? rev) self.rev;
          imports = machine.modules ++ (import ./modules);
        })
        nix-serve-ng.nixosModules.default
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };

  in rec {
    nixosConfigurations = builtins.mapAttrs buildMachine machines;
    apps = (import ./apps { inherit self nixpkgs nixosConfigurations; });
  };
}
