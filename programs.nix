{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim_configurable
    wget
    git
    firefox
    termite
    alacritty
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    lxappearance
    cryptsetup
    go
    kubectl
    yubikey-personalization
    yubikey-manager
  ];
}
