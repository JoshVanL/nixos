{ pkgs, ... }:

{
  programs.dconf.enable = true;

  home-manager.users.josh = { pkgs, ... }: {
    gtk = {
      enable = true;
      font = {
        name = "San Francisco Display Regular";
      };
      theme = {
        name = "Arc-Dark";
        package = pkgs.arc-theme;
      };
    };
  };
}
