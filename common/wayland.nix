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

  environment.sessionVariables = rec {
    XDG_SESSION_TYPE    = "wayland";
    XDG_CURRENT_DESKTOP = "wayfire";
    MOZ_ENABLE_WAYLAND  = "1";
  };
}
