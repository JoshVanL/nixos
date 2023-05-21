{ self
, nixpkgs
, nixosConfigurations
}:
with nixpkgs.lib;

let
  # mkApp is helper function to create a value nix flake app attr.
  mkApp = drv: { type = "app"; program = "${drv}/bin/${drv.name}"; };

  # pkgsys is a helper to return the nixpkgs pkgset for a given system.
  pkgsys = system: import nixpkgs { inherit system; };

  # targetSystems is a list of all the systems which are defined in the
  # nixosConfigurations attrset.
  targetSystems = lists.unique (mapAttrsToList (_: machine: machine.config.me.base.hardware.system) nixosConfigurations);

  # commit-rev is the git revision of the flake.
  commit-rev = if self ? rev then self.rev else "";

  loggerFuncsString = ''
    function err {
        echo -e "\033[41m$1\033[0m"
    }

    function info {
        echo -e "\033[44m$1\033[0m"
    }

    function ask {
        echo -e "\033[45m$1\033[0m"
    }
  '';

  mustBeRootString = ''
    if [[ "$EUID" -gt 0 ]]; then
      err "Must run install as root user (i.e. with sudo)."
      err "Exiting."
      exit 1
    fi
  '';

  # allMachines is a list of all the machines in the nixosConfigurations.
  allMachines = builtins.attrNames nixosConfigurations;

  # usernamesBashMap is a bash map of machines to thir usernames.
  usernamesBashMap = concatStringsSep " " (map (name:
    "[\"" + name + "\"]=\"" + nixosConfigurations.${name}.config.me.base.username + "\""
  ) allMachines);

  # sysMachines returns a string of the names of the machines which have the
  # same architecture as the given system.
  sysMachines = system: "\"" + (concatStringsSep "\" \"" (builtins.attrNames (
    filterAttrs (name: value: value.config.me.base.hardware.system == system) nixosConfigurations
  ))) + "\"";

  # Add helper functions to the lib attrset.
  lib = nixpkgs.lib // {
    inherit pkgsys mkApp targetSystems;
    inherit commit-rev loggerFuncsString mustBeRootString;
    inherit allMachines usernamesBashMap sysMachines;
  };

in fold (attrset: acc: recursiveUpdate attrset acc) {} [
  (import ./install.nix { inherit lib ; })
  (import ./post-install.nix { inherit lib; })
]
