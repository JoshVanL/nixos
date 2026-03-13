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
    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        git-extras
        gh
        gh-dash
      ];

      programs.git = {
        enable = true;
        ignores = [
          "*.swp"
          ".envrc"
        ];
        settings = {
          user.email = cfg.email;
          user.name  = cfg.username;
          init.defaultBranch = "main";
        };
      };
    };
  };
}
