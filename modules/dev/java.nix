{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.java;

in {
  options.me.dev.java = {
    enable = mkEnableOption "dev.java";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      programs.java.enable = true;
    };
  };
}
