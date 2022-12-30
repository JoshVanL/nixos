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
  };
}
