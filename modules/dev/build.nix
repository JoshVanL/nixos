{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.build;

in {
  options.me.dev.build = {
    enable = mkEnableOption "dev.build";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      gnumake
      mechanical-markdown
    ];
  };
}
