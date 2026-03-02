{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.ai;

in {
  options.me.dev.ai = {
    enable = mkEnableOption "dev.ai";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /persist/home/.config/chatgpt 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.config/chatgpt - - - - /persist/home/.config/chatgpt"
      "L+ /home/${config.me.username}/.claude.json - - - - /keep/home/.claude.json"
      "L+ /home/${config.me.username}/.claude - - - - /keep/home/.claude"
      "L+ /home/${config.me.username}/.gemini - - - - /keep/home/.gemini"
    ];

    me.nixpkgs.allowedUnfree = [ "claude-code" ];

    home-manager.users.${config.me.username} = {

      home = {
        packages = with pkgs; [
          chatgpt-cli
          claude-code
          gemini-cli
        ];
      };
    };
  };
}
