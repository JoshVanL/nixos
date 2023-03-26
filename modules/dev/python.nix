{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.python;

in {
  options.me.dev.python = {
    enable = mkEnableOption "dev.python";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      python3
    ];
  };
}
