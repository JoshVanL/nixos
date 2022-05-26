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

  services.pcscd.enable = true;

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
