{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.security.yubikey;

in {
  options.me.security.yubikey = {
    enable = mkEnableOption "yubikey";

    pam = {
      enable = mkEnableOption "yubikey pam";
      authorizedIDs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Authorized keys for yubikey";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.ssh.startAgent = mkIf config.me.networking.ssh.enable true;

    security.pam.yubico = mkIf cfg.pam.enable { enable = true; id = "16"; };

    home-manager.users.${config.me.base.username} = {
      home.packages = with pkgs; [
        gnupg
        yubikey-personalization
        yubikey-manager
        pinentry
        pinentry-curses
      ];

      pam.yubico.authorizedYubiKeys.ids = mkIf cfg.pam.enable cfg.pam.authorizedIDs;

      programs.zsh.shellAliases = mkIf config.me.programs.zsh.enable {
        imps = "ssh-keygen -K && mkdir -p ~/.ssh && mv id*_rk.pub ~/.ssh/id_ed25519_sk.pub && mv id*_rk ~/.ssh/id_ed25519_sk";
      };
    };
  };
}
