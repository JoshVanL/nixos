{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "sshingress" cfg.assume) {
    me = {
      base.boot.initrd.ssh = {
        enable = true;
        authorizedKeys = config.me.security.joshvanl.sshPublicKeys;
      };
      networking.ssh = {
        enable = true;
        ingress = {
          enable = true;
          authorizedKeys = config.me.security.joshvanl.sshPublicKeys;
        };
      };
      security.yubikey.pam = {
        enable = true;
        authorizedIDs = config.me.security.joshvanl.yubikeyIDs;
      };
    };
  };
}
