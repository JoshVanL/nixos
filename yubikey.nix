{ config, lib, pkgs, ... }:

{

  environment = {
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent updatestartuptty /bye >/dev/null
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
    systemPackages = with pkgs; [
      gnupg
      yubikey-personalization
      yubikey-manager
    ];
  };

  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };
}
