#!/usr/bin/env bash

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export BLUE_BG="\033[44m"

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

info "Enter password for josh ..."
passwd josh

info "Adding home-manager channel ..."
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixos
nix-channel --update

info "Setting up fonts ..."
cd /persist/etc/nixos
git submodule init
git submodule update
cd -

info "Switching nixos configuration ..."
nixos-rebuild switch

info "root: Switching home-manager ..."
home-manager switch

info "Changing ownership of /persist/etc/nixos to josh ..."
chown -R josh:wheel /persist/etc/nixos

info "josh: Switching home-manager ..."
sudo -H -u josh bash -c 'home-manager switch'

info "Ready. Powering off."
read -p "Press any key to continue ..."
poweroff
