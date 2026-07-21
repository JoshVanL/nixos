{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.claude;

  claude-statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [ jq git hostname ];
    text = builtins.readFile ./claude-statusline.sh;
  };

  skillNames = builtins.attrNames (builtins.readDir ./skills);

  claudeSettings = pkgs.writeText "claude-settings.json" (builtins.toJSON {
    permissions = {
      deny = [
        "Bash(git push*)"
        "Bash(git commit*)"
        "Bash(gh pr create*)"
        "Bash(gh pr close*)"
        "Bash(gh pr merge*)"
        "Bash(gh pr edit*)"
        "Bash(gh pr comment*)"
        "Bash(gh pr review*)"
        "Bash(gh pr reopen*)"
        "Bash(gh pr ready*)"
      ];
    };
    statusLine = {
      type = "command";
      command = "${claude-statusline}/bin/claude-statusline";
    };
    enabledPlugins = {
      "typescript-lsp@claude-plugins-official" = true;
    };
    effortLevel = "high";
    skipDangerousModePermissionPrompt = true;
  });

in {
  options.me.dev.claude = {
    enable = mkEnableOption "dev.claude";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "L+ /home/${config.me.username}/.claude.json - - - - /persist/home/.claude.json"
      "L+ /home/${config.me.username}/.claude - - - - /persist/home/.claude"
      "C+ /persist/home/.claude/settings.json 0600 ${config.me.username} wheel - ${claudeSettings}"
      "d /persist/home/.claude/skills 0755 ${config.me.username} wheel -"
    ] ++ map (name:
      "L+ /persist/home/.claude/skills/${name} - - - - ${./skills}/${name}"
    ) skillNames;

    me.nixpkgs.allowedUnfree = [ "claude-code" ];

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        claude-code
        claude-statusline
      ];
    };
  };
}
