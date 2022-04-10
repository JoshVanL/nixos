{ config, pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];

  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  services.pcscd.enable = true;
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };
}
