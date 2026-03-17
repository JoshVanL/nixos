{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.ai;

  claude-d = pkgs.writeShellApplication {
    name = "claude-d";
    runtimeInputs = with pkgs; [ claude-code ];
    text = ''
      if [ "''${CDGO_SANDBOX:-}" != "1" ]; then
        echo ">> error: `claude-d` must be run inside a `cdgo-sandbox`," >&2
        exit 1
      fi
      claude --dangerously-skip-permissions "$@"
    '';
  };

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
          claude-d
          gemini-cli
        ];
      };
    };
  };
}
