{ nixpkgs
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

  # Add helper functions to the lib attrset.
  lib = nixpkgs.lib // { inherit pkgsys mkApp targetSystems; };

in fold (attrset: acc: recursiveUpdate attrset acc) {} [
  (import ./install.nix { inherit lib nixosConfigurations; })
  (import ./post-install.nix { inherit lib; })
]
