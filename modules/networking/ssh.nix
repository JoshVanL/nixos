{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.ssh;

in {
  options.me.networking.ssh = {
    enable = mkEnableOption "ssh";
  };

  config = mkIf cfg.enable {
    systemd.user.tmpfiles.rules = [
      "d /persist/home/.ssh 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.ssh/known_hosts - - - - /persist/home/.ssh/known_hosts"
    ];

    home-manager.users.${config.me.username} = {
      programs.ssh = {
        enable = true;
      };

      programs.zsh.shellAliases = mkIf config.me.programs.zsh.enable {
        sshbye = "gpg-connect-agent updatestartuptty /bye";
        syk = "killall ssh-agent && eval $(ssh-agent) && ssh-add -K";
      };
    };
  };
}
