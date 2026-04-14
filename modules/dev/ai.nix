{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.ai;

in {
  options.me.dev.ai = {
    enable = mkEnableOption "dev.ai";
  };

  config = mkIf cfg.enable {
    me.dev.claude.enable = true;

    systemd.tmpfiles.rules = [
      "d /persist/home/.config/chatgpt 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/chatgpt - - - - /persist/home/.config/chatgpt"
      "L+ /home/${config.me.username}/.gemini - - - - /keep/home/.gemini"
    ];

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        chatgpt-cli
        gemini-cli
      ];
    };
  };
}
