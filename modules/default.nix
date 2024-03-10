{ self, nixpkgs, inputs }:
with nixpkgs.lib;
let
  lib = (import ../lib { lib = nixpkgs.lib; });
  overlays = import ../overlays {inherit lib; };
  pkgs = import ../pkgs {inherit lib nixpkgs; };
  machines = import ../machines {inherit lib; };

  nixosModules = { imports = (lib.defaultImport ./.); };

  inpWithModules = filterAttrs (_: v: (hasAttrByPath ["nixosModules" "default"] v)) inputs;
  inpModules = mapAttrsToList (_: inp: inp.nixosModules.default) inpWithModules;

  machineModules = machineName: [
    nixosModules
    overlays.modules
    pkgs.modules
    machines.${machineName}.modules
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
    inputs.nur.nixosModules.nur
  ] ++ inpModules;

  machineConfigs = builtins.mapAttrs (name: machine: {
    system = machine.system;
    modules = (machineModules name);
    specialArgs = { inherit lib; };
  }) machines;

  nixosConfigurations = builtins.mapAttrs (_: m:
    makeOverridable nixosSystem m
  ) machineConfigs;

  apps = import ../apps { inherit self nixpkgs nixosConfigurations; };

in {
  inherit nixosConfigurations apps nixosModules;
  inherit (overlays) overlays;
  inherit (pkgs) packages;
}
