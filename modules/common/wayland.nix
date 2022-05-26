{ config, lib, pkgs, ... }:

{
  programs.sway = {
    enable = true;
    wrapperFeatures = {
      gtk = true;
    };
  };

  environment.systemPackages = with pkgs; [
    xwayland
  ];

  # Screen sharing
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-wlr
      ];
      wlr.enable = true;
    };
  };


  # Notifications
  home-manager.users.josh = { pkgs, ... }: {
    programs.mako = {
      enable          = true;
      defaultTimeout  = 0;
      font            = "San Francisco Display Regular";
      backgroundColor = "#404552FF";
      textColor       = "#DDDDDDFF";
      borderColor     = "#7C818CFF";
    };
  };

  # Global env vars.
  environment.sessionVariables = rec {
    XDG_DATA_HOME       = "\${HOME}/.local/share";
    XDG_SESSION_TYPE    = "wayland";
    XDG_CURRENT_DESKTOP = "Wayfire";
    MOZ_ENABLE_WAYLAND  = "1";
  };
}
