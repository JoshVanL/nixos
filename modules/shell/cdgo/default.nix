{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.cdgo;

  cdgoSH = pkgs.writeShellApplication {
    name = "__cdgo";
    runtimeInputs = with pkgs; [ git gh jq coreutils ];
    text = builtins.readFile ./cdgo.sh;
  };

in {
  options.me.shell.cdgo = {
    enable = mkEnableOption "cdgo";
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
