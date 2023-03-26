{ lib, pkgs, config, ... }:
with lib;

{
  options.me.base.username = mkOption {
    type = types.str;
  };

  imports = [
    ./os.nix
    ./hardware.nix
    ./boot.nix
  ];
}
