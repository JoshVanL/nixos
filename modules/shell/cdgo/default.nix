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

  cdgoSandboxSH = pkgs.writeShellApplication {
    name = "__cdgo_sandbox";
    runtimeInputs = with pkgs; [ bubblewrap coreutils ];
    runtimeEnv = {
      CDGO_SANDBOX_EXTRA_RO_BINDS = concatStringsSep "\n" cfg.sandbox.extraRoBinds;
    };
    text = builtins.readFile ./cdgo-sandbox.sh;
  };

  claudeDSH = pkgs.writeShellApplication {
    name = "claude-d";
    runtimeInputs = with pkgs; [ claude-code ];
    text = ''
      if [ "''${CDGO_SANDBOX:-}" != "1" ]; then
        echo ">> error: \`claude-d\` must be run inside a \`cdgo-sandbox\`." >&2
        exit 1
      fi
      claude --dangerously-skip-permissions "$@"
    '';
  };

in {
  options.me.shell.cdgo = {
    enable = mkEnableOption "cdgo";

    groups = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = "Named groups of repos. e.g. { daprgo = [ \"dapr/dapr\" \"dapr/kit\" ]; }";
    };

    sandbox = {
      enable = mkEnableOption "cdgo sandbox isolation via bubblewrap";

      extraRoBinds = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra host paths to bind read-only into the sandbox.";
      };
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = [ cdgoSH ] ++ (optionals cfg.sandbox.enable [ cdgoSandboxSH claudeDSH ]);

      programs.zsh.initContent = ''
        cdgo() { cd "$(__cdgo "$@")" || return; }
      '' + (optionalString cfg.sandbox.enable ''
        cdgo-sandbox() {
          local dir
          dir="$(__cdgo "$@")" || return
          __cdgo_sandbox "$dir"
        }
        if [ -n "''${CDGO_SANDBOX:-}" ]; then
          PROMPT="[sandbox:$(basename "$CDGO_WORKSPACE")] $PROMPT"
        fi
      '') + ''
        _cdgo() {
          if (( CURRENT == 2 )); then
            local -a dirs
            local base="$HOME/sandbox/workspace"
            if [[ -d "$base" ]]; then
              dirs=("$base"/*(/:t))
              compadd -a dirs
            fi
          else
            local -a groups=(${lib.concatStringsSep " " (map (g: "'${g}'") (attrNames cfg.groups))})
            compadd -a groups
          fi
        }
        compdef _cdgo cdgo
      '' + (optionalString cfg.sandbox.enable ''
        compdef _cdgo cdgo-sandbox
      '');
    };
  };
}
