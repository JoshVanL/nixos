{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
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
    zip unzip
    git-extras
    bitwarden-cli
    fast-cli
    ripgrep

    # work
    gnumake
    calc
    jq
    gcc
    evince
    openssl
    grim
    slurp
    direnv
    tree
  ];
}
