{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "josh" cfg.assume) {
    me = {
      dev.git.enable = true;
      data.zfs_uploader = {
        enable = true;
        logPath = "/keep/run/zfs_uploader/zfs_uploader.log";
        configPath = "/persist/etc/zfs_uploader/config.cfg";
      };
      shell = {
        neovim = {
          enable = true;
          coPilot.enable = true;
        };
        zsh.enable = true;
      };
      security = {
        #bitwarden.enable = true;
        yubikey.enable = true;
      };
      networking = {
        ssh.enable = true;
        tailscale.enable = true;
      };
    };
  };
}
