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
    assertions = [
      {assertion = cfg.enable || !cfg.ingress.enable; message = "SSH must be enabled to enable ingress ssh";}
    ];

    systemd.tmpfiles.rules = [
      "d /home/${config.me.username}/.ssh 0755 ${config.me.username} wheel - -"
      "d /persist/home/.ssh 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.ssh/known_hosts - - - - /persist/home/.ssh/known_hosts"
    ] ++ (optionals cfg.ingress.enable [
      "d /etc/ssh 0755 root root - -"
      "d /keep/etc/ssh 0755 root root - -"
      "L+ /etc/ssh/ssh_host_ed25519_key - - - - /keep/etc/ssh/ssh_host_ed25519_key"
      "L+ /etc/ssh/ssh_host_ed25519_key.pub - - - - /keep/etc/ssh/ssh_host_ed25519_key.pub"
      "L+ /etc/ssh/ssh_host_rsa_key - - - - /keep/etc/ssh/ssh_host_rsa_key"
      "L+ /etc/ssh/ssh_host_rsa_key.pub - - - - /keep/etc/ssh/ssh_host_rsa_key.pub"
    ]);

    users.users.${config.me.username}.openssh.authorizedKeys.keys = mkIf cfg.ingress.enable cfg.ingress.authorizedKeys;

    services.openssh = mkIf cfg.ingress.enable {
      enable = true;
      settings = {
        passwordAuthentication = false;
        PasswordAuthentication = false;
        kbdInteractiveAuthentication = true;
      };
    };

    home-manager.users.${config.me.username} = {
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
