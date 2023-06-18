{ self, lib, nixpkgs, inputs }:
with lib;
let
  overlays = import ../overlays {inherit lib; };
  pkgs = import ../pkgs {inherit lib nixpkgs; };
  machines = import ../machines {inherit lib; };

  modulesList = (dirs ./.) ++ (nixFilesNoDefault ./.);
  meModules = { imports = map (name: ./${name}) modulesList; };

  inpWithModules = filterAttrs (_: v: (hasAttrByPath ["nixosModules" "default"] v)) inputs;
  inpModules = mapAttrsToList (_: inp: inp.nixosModules.default) inpWithModules;

  machineModules = machineName: [
    meModules
    overlays.modules
    pkgs.modules
    machines.${machineName}.modules
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ] ++ inpModules;

  machineConfigs = builtins.mapAttrs (name: machine: {
    system = machine.system;
    modules = (machineModules name);
  }) machines;

  nixosConfigurations = builtins.mapAttrs (_: m:
    makeOverridable nixosSystem m
  ) machineConfigs;

  apps = import ../apps { inherit self nixpkgs nixosConfigurations; };

in {
  inherit nixosConfigurations apps;
  overlays = overlays.output;
  packages = pkgs.output;
  nixosModules = meModules;
  machines = machineConfigs;
}
