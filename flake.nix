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
    pkgsOverlays = system: [
      joshvanldwm.overlays.${system}
    ] ++
    lib.mapAttrsToList (name: _: import ./overlays/${name}) (lib.filterAttrs
      (name: entryType: lib.hasSuffix ".nix" name && entryType == "regular")
      (builtins.readDir ./overlays)
    );

    nixosModulesPkgs = sys: {
      # propagate git revision
      system.configurationRevision = lib.mkIf (self ? rev) self.rev;
      nixpkgs = {
        overlays = (pkgsOverlays sys);
        config = {
          packageOverrides = pkgs: with pkgs; {
            go-jwt = pkgs.callPackage ./pkgs/go-jwt {};
            gomarkdoc = pkgs.callPackage ./pkgs/gomarkdoc {};
            go-protobuf = pkgs.callPackage ./pkgs/go-protobuf {};
            go-protobuf-grpc = pkgs.callPackage ./pkgs/go-protobuf-grpc {};
            helm = pkgs.callPackage ./pkgs/helm {};
            kind = pkgs.callPackage ./pkgs/kind {};
            paranoia = pkgs.callPackage ./pkgs/paranoia {};
            vcert = pkgs.callPackage ./pkgs/vcert {};
            gke-gcloud-auth-plugin = pkgs.callPackage ./pkgs/gke-gcloud-auth-plugin {};
            zfs_uploader = pkgs.callPackage ./pkgs/zfs_uploader {
              python3 = pkgs.python3;
              python3Packages = pkgs.python3Packages;
            };
            mockery = pkgs.callPackage ./pkgs/mockery {};
            interfacebloat = pkgs.callPackage ./pkgs/interfacebloat {};
            dupword = pkgs.callPackage ./pkgs/dupword {};
            shadow-go = pkgs.callPackage ./pkgs/shadow {};
          };
        };
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
          (nixosModulesPkgs system)
          (import (./machines + "/${system}/${machine}.nix"))
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.josh = { lib, pkgs, config, ... }: with lib; {
              home.stateVersion = "22.11";
            };
          }
        ];
      };
    };

  in {
    nixosConfigurations = builtins.listToAttrs (lib.flatten (
      (map
        ( machine: [ (build-machine machine "x86_64-linux") ])
        (machines "x86_64-linux"))
      #++
      #(map
      #  ( machine: [ (build-machine machine "aarch64-linux") ])
      #  (machines "aarch64-linux"))
    ));
  };
}
