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

USERNAME=$(ls /keep/etc/users)

info "Changing ownership of /keep/etc/nixos to ${USERNAME} ..."
chown -R ${USERNAME}:wheel /keep/etc/nixos

info "Setting correct remote git for nixos ..."
cd /keep/etc/nixos
sudo -u ${USERNAME} git remote set-url origin git@github.com:joshvanl/nixos
sudo -u ${USERNAME} git checkout main

info "Adding unstable channel ..."
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

info "Switching nixos configuration ..."
rm -f /home/${USERNAME}/.zsh_history
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake "/keep/etc/nixos#"

info "Cleaning up the garbage ..."
rm -f /keep/keep
nix-collect-garbage -d

info "Ready. Rebooting ..."
read -p "Press any key to continue ..."
reboot
