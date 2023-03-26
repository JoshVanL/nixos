{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.ssh;

  sshbyeSH = pkgs.writeShellApplication {
    name = "sshbye.sh";
    runtimeInputs = with pkgs; [ gnupg ];
    text = ''
      gpg-connect-agent updatestartuptty /bye
    '';
  };

  sykSH = pkgs.writeShellApplication {
    name = "syk.sh";
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
    systemd.user.tmpfiles.rules = [
      "d /persist/home/.ssh 0755 ${config.me.base.username} wheel - -"
      "L+ /home/${config.me.base.username}/.ssh/known_hosts - - - - /persist/home/.ssh/known_hosts"
    ];

    users.users.${config.me.base.username}.openssh.authorizedKeys.keys = mkIf cfg.ingress.enable cfg.ingress.authorizedKeys;

    services.openssh = mkIf cfg.ingress.enable {
      enable = true;
      settings = {
        passwordAuthentication = false;
        kbdInteractiveAuthentication = true;
      };
    };

    home-manager.users.${config.me.base.username} = {
      programs.ssh = {
        enable = true;
      };

      programs.zsh.shellAliases = mkIf config.me.programs.zsh.enable {
        sshbye = "${sshbyeSH}/bin/sshbye.sh";
        syk = "${sykSH}/bin/syk.sh";
      };
    };
  };
}
