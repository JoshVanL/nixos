{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.node;

in {
  options.me.dev.node = {
    enable = mkEnableOption "dev.node";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        nodejs
        nodePackages.typescript
        nodePackages.typescript-language-server
      ];
    };
  };
}
