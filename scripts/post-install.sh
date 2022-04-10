#!/usr/bin/env bash

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export BLUE_BG="\033[44m"

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

info "Enter password for josh"
passwd josh

info "Setting up nixos directory"
rm -r /etc/nixos
ln -s /persist/etc/nixos /etc/nixos

info "Setting up .config directories"
ln -s "/etc/nixos/dotfiles/.config" "/root/.config"
ln -s "/etc/nixos/dotfiles/.config" "/home/josh/.config"

info "Adding home-manager channel"
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixos
nix-channel --update

info "Setting up fonts"
git submodule init
git submpdule update

info "Switching nixos configuration"
nixos-rebuild switch

info "root: Switching home-manager"
home-manager switch

info "josh: Switching home-manager"
su josh
home-manager switch
exit

info "Ready. Powering off."
read -p "Press any key to continue"
poweroff
