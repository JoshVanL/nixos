{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    cryptsetup
    killall
    wget
    firefox
    chromium
    imv
    pavucontrol
    htop
    bat
    fzf
    pulseaudio
    backblaze-b2
    unzip

    # work
    gnumake
    go_1_18
    calc
    jq
    gcc
    evince
  ];
}
