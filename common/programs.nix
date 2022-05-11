{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    cryptsetup
    killall
    firefox
    chromium
    imv
    pavucontrol
    htop
    bat
    fzf
    pulseaudio
    wdisplays
    backblaze-b2

    # work
    gnumake
    go_1_18
    kubectl
    calc
    jq
  ];
}
