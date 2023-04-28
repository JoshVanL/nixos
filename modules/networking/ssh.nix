{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.ssh;

  sshbyeSH = pkgs.writeShellApplication {
    name = "sshbye";
    runtimeInputs = with pkgs; [ gnupg ];
    text = ''
      gpg-connect-agent updatestartuptty /bye
    '';
  };

  sykSH = pkgs.writeShellApplication {
    name = "syk";
    runtimeInputs = with pkgs; [ killall openssh ];
    text = ''
      killall ssh-agent
      eval "$(ssh-agent)"
      ssh-add -K
    '';
  };

in {
  options.me.networking.ssh = {
    enable = mkEnableOption "ssh";

    ingress = {
      enable = mkEnableOption "ingress ssh";
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of authorized keys for ingress ssh";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /home/${config.me.base.username}/.ssh 0755 ${config.me.base.username} wheel - -"
      "d /persist/home/.ssh 0755 ${config.me.base.username} wheel - -"
      "L+ /home/${config.me.base.username}/.ssh/known_hosts - - - - /persist/home/.ssh/known_hosts"
      "d /persist/etc/ssh 0755 root root - -"
      "d /etc/ssh 0755 root root - -"
      "L+ /etc/ssh/ssh_host_ed25519_key - - - - /persist/etc/ssh/ssh_host_ed25519_key"
      "L+ /etc/ssh/ssh_host_ed25519_key.pub - - - - /persist/etc/ssh/ssh_host_ed25519_key.pub"
    ];

    users.users.${config.me.base.username}.openssh.authorizedKeys.keys = mkIf cfg.ingress.enable cfg.ingress.authorizedKeys;

    services.openssh = mkIf cfg.ingress.enable {
      enable = true;
      settings = {
        passwordAuthentication = false;
        PasswordAuthentication = false;
        kbdInteractiveAuthentication = true;
      };
    };

    home-manager.users.${config.me.base.username} = {
      programs.ssh = {
        enable = true;
        userKnownHostsFile = "/persist/home/.ssh/known_hosts";
      };
      home.packages = [
        sshbyeSH
        sykSH
      ];
    };
  };
}
