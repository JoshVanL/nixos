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
    git-extras
    tailscale
    bitwarden
    bitwarden-cli

    # work
    gnumake
    go_1_19
    calc
    jq
    gcc
    evince
    openssl
    grim
    slurp
    direnv
    nodejs
    tree
  ];
}
