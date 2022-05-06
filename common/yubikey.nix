{ config, lib, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      gnupg
      yubikey-personalization
      yubikey-manager
      pinentry
      pinentry-curses
    ];
  };

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
