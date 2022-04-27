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

info "Changing ownership of /persist/etc/nixos to josh ..."
sudo chown -R josh:wheel /persist/etc/nixos

info "Switching nixos configuration ..."
rm /home/josh/.zsh_history
sudo nixos-rebuild switch

# Ensure we clean up from install if exists.
rm -f /persist/persist

info "Ready. Powering off."
read -p "Press any key to continue ..."
poweroff
