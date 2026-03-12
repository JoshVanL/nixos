{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.cdgo;

  groupsFile = pkgs.writeText "cdgo-groups.json" (builtins.toJSON cfg.groups);

  cdgoSH = pkgs.writeShellApplication {
    name = "__cdgo";
    runtimeInputs = with pkgs; [ git gh jq coreutils ];
    runtimeEnv = {
      CDGO_GROUPS_FILE = "${groupsFile}";
    };
    text = builtins.readFile ./cdgo.sh;
  };

in {
  options.me.shell.cdgo = {
    enable = mkEnableOption "cdgo";

    groups = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = "Named groups of repos. e.g. { daprgo = [ \"dapr/dapr\" \"dapr/kit\" ]; }";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = [ cdgoSH ];

      programs.zsh.initContent = ''
        cdgo() { cd "$(__cdgo "$@")" || return; }
      '';
    };
  };
}
