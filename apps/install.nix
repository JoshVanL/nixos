{ lib
, nixosConfigurations
}:

with lib;

let
  # Returns the names of the machines which have the same architecture as the
  # given system.
  sysMachines = system: concatStringsSep " " (builtins.attrNames (
    filterAttrs (name: value: value.config.me.base.hardware.system == system) nixosConfigurations
  ));

  # Extended from https://gist.github.com/mx00s/ea2462a3fe6fdaa65692fe7ee824de3e
  #
  # NixOS install script synthesized from:
  # - Erase Your Darlings (https://grahamc.com/blog/erase-your-darlings)
  # - ZFS Datasets for NixOS (https://grahamc.com/blog/nixos-on-zfs)
  # - NixOS Manual (https://nixos.org/nixos/manual/)
  install = system: (pkgsys system).writeShellApplication {
    name = "install.sh";
    runtimeInputs = with (pkgsys system); [ nix git zfs ];
    text = ''
      echo ${sysMachines system}
    '';
  };

in listToAttrs (map (system:
  nameValuePair "${system}" {install = mkApp (install system);}
) targetSystems)
