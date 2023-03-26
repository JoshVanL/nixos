{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.security.bitwarden;

in {
  options.me.security.bitwarden = {
    enable = mkEnableOption "bitwarden";
  };

  config = mkIf cfg.enable {
    systemd.user.tmpfiles.rules = [
      "d /persist/home/.config/Bitwarden 0755 ${config.me.base.username} wheel - -"
      "d '/persist/home/.config/Bitwarden\ CLI' 0755 ${config.me.base.username} wheel - -"
      "L+ /home/${config.me.base.username}/.config/Bitwarden - - - - /persist/home/.config/Bitwarden"
      "L+ '/home/${config.me.base.username}/.config/Bitwarden\ CLI' - - - - '/persist/home/.config/Bitwarden\ CLI'"
    ];

    home-manager.users.${config.me.base.username}.home = {
      packages = with pkgs; [
        bitwarden-cli
      ];
    };
  };
}
