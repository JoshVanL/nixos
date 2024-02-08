{ lib, pkgs, config, ... }:
with lib;

{
  config = mkIf config.me.window-manager.enable {
    systemd.tmpfiles.rules = [
      "d /persist/home 0755 ${config.me.username} wheel - -"
      "d /persist/home/.mozilla  0755 ${config.me.username} wheel - -"
      "d /persist/home/.config/chromium  0755 ${config.me.username} wheel - -"
      "d /persist/home/.cache/mozilla 0755 ${config.me.username} wheel - -"
      "d /persist/home/.cache/chromium 0755 ${config.me.username} wheel - -"
      "d /keep/home/downloads 0755 ${config.me.username} wheel - -"
      "d /persist/home/documents 0755 ${config.me.username} wheel - -"

      "L+ /home/${config.me.username}/.mozilla - - - - /persist/home/.mozilla"
      "L+ /home/${config.me.username}/.cache/mozilla - - - - /persist/home/.cache/mozilla"
      "L+ /home/${config.me.username}/.config/chromium - - - - /persist/home/.config/chromium"
      "L+ /home/${config.me.username}/.cache/chromium - - - - /persist/home/.cache/chromium"
      "L+ /home/${config.me.username}/downloads - - - - /keep/home/downloads"
      "L+ /home/${config.me.username}/Downloads - - - - /keep/home/downloads"
      "L+ /home/${config.me.username}/documents - - - - /persist/home/documents"
    ];

    home-manager.users.${config.me.username} = {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";
        };
      };

      home.packages = with pkgs; [
        chromium
        firefox
      ];

      home.sessionVariables = {
        BROWSER = "firefox";
      };
    };
  };
}
