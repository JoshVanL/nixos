{ lib, pkgs, config, ... }:
with lib;

{
  options = {
    me.username = mkOption {
      type = types.str;
    };
  };

  imports = [
    ./os.nix
    ./hardware.nix
  ];
}
