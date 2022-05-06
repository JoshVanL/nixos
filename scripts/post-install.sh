#!/usr/bin/env bash

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export RED_BG="\033[41m"
export BLUE_BG="\033[44m"

function err {
    echo -e "${RED_BG}$1${COLOR_RESET}"
}

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

if [ "$EUID" -ne 0 ]; then
  err "Must run as root"
  exit 1
fi

info "Setting correct remote git for nixos ..."
cd /persist/etc/nixos
git remote set-url origin git@github.com:joshvanl/nixos
git checkout -b main

info "Adding unstable channel ..."
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

info "Changing ownership of /persist/etc/nixos to josh ..."
chown -R josh:wheel /persist/etc/nixos

info "Switching nixos configuration ..."
rm -f /home/josh/.zsh_history
nixos-rebuild switch --upgrade-all -I nixos-config=/persist/etc/nixos/configuration.nix

info "Cleaning up the garbage ..."
rm -f /persist/persist
nix-collect-garbage -d

info "Ready. Powering off ..."
read -p "Press any key to continue ..."
poweroff
