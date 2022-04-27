{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    cryptsetup
    killall
    firefox
    chromium
    imv

    # work
    gnumake
    go_1_18
    kubectl
    calc
    jq
  ];
}
