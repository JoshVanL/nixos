{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.yubikey;
in {
  options.services.josh.yubikey = {
    enable = mkEnableOption "yubikey";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnupg
      yubikey-personalization
      yubikey-manager
      pinentry
      pinentry-curses
    ];

    programs.ssh.startAgent = true;

    systemd.tmpfiles.rules = [
      "d /persist/home/.ssh 0755 josh wheel - -"
      "d /home/.ssh 0755 josh wheel - -"
      "L+ /home/josh/.ssh/known_hosts - - - - /persist/home/.ssh/known_hosts"
    ];
  };
}
