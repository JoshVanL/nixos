#!/usr/bin/env bash

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export BLUE_BG="\033[44m"

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

info "Adding unstable channel ..."
sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixos
sudo nix-channel --update

info "Setting up fonts ..."
cd /persist/etc/nixos
git submodule init
git submodule update
cd -

info "Changing ownership of /persist/etc/nixos to josh ..."
sudo chown -R josh:wheel /persist/etc/nixos

info "Switching nixos configuration ..."
sudo nixos-rebuild switch

info "Switching nixos configuration again ..."
sudo nixos-rebuild switch

info "Ready. Powering off."
read -p "Press any key to continue ..."
poweroff
