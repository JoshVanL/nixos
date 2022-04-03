{ config, pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Depending on the details of your configuration, this section might be necessary or not;
  # feel free to experiment
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  programs.gnupg.agent.pinentryFlavor = "curses";

  services.pcscd.enable = true;
}
