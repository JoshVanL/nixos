{ lib, pkgs, config, ... }:
with lib;

{
  config = mkIf config.me.window-manager.enable {
    systemd.user.tmpfiles.rules = [
      "d /persist/home/.mozilla  0755 ${config.me.username} wheel - -"
      "d /persist/home/.config/chromium  0755 ${config.me.username} wheel - -"
      "d /persist/home/.cache/mozilla 0755 ${config.me.username} wheel - -"
      "d /persist/home/.cache/chromium 0755 ${config.me.username} wheel - -"
      "d /persist/home/downloads 0755 ${config.me.username} wheel - -"
      "d /persist/home/documents 0755 ${config.me.username} wheel - -"

      "L+ /home/${config.me.username}/.mozilla - - - - /persist/home/.mozilla"
      "L+ /home/${config.me.username}/.cache/mozilla - - - - /persist/home/.cache/mozilla"
      "L+ /home/${config.me.username}/.config/chromium - - - - /persist/home/.config/chromium"
      "L+ /home/${config.me.username}/.cache/chromium - - - - /persist/home/.cache/chromium"
      "L+ /home/${config.me.username}/downloads - - - - /persist/home/downloads"
      "L+ /home/${config.me.username}/Downloads - - - - /persist/home/downloads"
      "L+ /home/${config.me.username}/documents - - - - /persist/home/documents"
    ];

    home-manager.users.${config.me.username}.home = {
      packages = with pkgs; [
        chromium
        firefox
      ];

      sessionVariables = {
        BROWSER = "firefox";
      };
    };
  };
}
