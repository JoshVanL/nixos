{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.git;

in {
  options.me.dev.git = {
    enable = mkEnableOption "git";

    email = mkOption {
      type = types.str;
      default = "";
    };

    username = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username} = {
      home.packages = with pkgs; [
        git-extras
      ];

      programs.git = {
        enable = true;
        userEmail = cfg.email;
        userName  = cfg.username;
        ignores = [
          "*.swp"
          ".envrc"
        ];
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
        };
      };
    };
  };
}
