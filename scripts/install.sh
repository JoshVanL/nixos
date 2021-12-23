#!/usr/bin/env bash

# Extended from https://gist.github.com/mx00s/ea2462a3fe6fdaa65692fe7ee824de3e

#
# NixOS install script synthesized from:
#
#   - Erase Your Darlings (https://grahamc.com/blog/erase-your-darlings)
#   - ZFS Datasets for NixOS (https://grahamc.com/blog/nixos-on-zfs)
#   - NixOS Manual (https://nixos.org/nixos/manual/)
#
# Example: `sudo ./install.sh
#

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

if [[ "$EUID" > 0 ]]; then
    err "Must run as root"
    exit 1
fi

AVAILABLE_DISKS=($(lsblk -d | tail -n+2 | cut -d" " -f1))
DISK=""
PS3="Select a disk to format and install: "
select d in "${AVAILABLE_DISKS[@]}"
do
  export DISK=$d
	break
done
export DISK_PATH="/dev/${DISK}"

PARTITION_PREFIX=""
PS3="Select a partition prefix:"
select p in "" "p"
do
  export PARTITION_PREFIX=$p
	break
done

AVAILABLE_HOSTS=$()
HOSTNAME=""
PS3="Select a hostname: "
for f in $(find $(git rev-parse --show-toplevel)/hosts -type f)
do
	AVAILABLE_HOSTS+=$(basename -- $f | cut -f 1 -d ".")
done
select host in "${AVAILABLE_HOSTS[@]}"
do
  export HOSTNAME=$host
	break
done

info "Enter password for 'josh' user ..."
mkdir -p /mnt/persist/etc/users
mkdir -p /etc/users
mkpasswd -m sha-512 | tr -d "\n\r" > /tmp/josh

################################################################################

export ZFS_POOL="rpool"

# ephemeral datasets
export ZFS_LOCAL="${ZFS_POOL}/local"
export ZFS_DS_ROOT="${ZFS_LOCAL}/root"
export ZFS_DS_NIX="${ZFS_LOCAL}/nix"

# persistent datasets
export ZFS_SAFE="${ZFS_POOL}/safe"
export ZFS_DS_PERSIST="${ZFS_SAFE}/persist"

export ZFS_BLANK_SNAPSHOT="${ZFS_DS_ROOT}@blank"

################################################################################

info "Running the UEFI (GPT) partitioning and formatting directions from the NixOS manual ..."
parted "$DISK_PATH" -- mklabel gpt
parted "$DISK_PATH" -- mkpart primary 512MiB 100%
parted "$DISK_PATH" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK_PATH" -- set 2 boot on
export DISK_PART_ROOT="${DISK_PATH}${PARTITION_PREFIX}1"
export DISK_PART_BOOT="${DISK_PATH}${PARTITION_PREFIX}2"

info "Formatting boot partition ..."
mkfs.fat -F 32 -n boot "$DISK_PART_BOOT"

info "Creating '$ZFS_POOL' ZFS pool for '$DISK_PART_ROOT' ..."
zpool create -f \
  -o ashift=12 \
  -o autotrim=on \
  -O compression=lz4 \
  -O dnodesize=auto \
  -O relatime=on \
  -O normalization=formD \
  -O encryption=aes-256-gcm \
  -O keylocation=prompt \
  -O keyformat=passphrase "$ZFS_POOL" "$DISK_PART_ROOT"

info "Creating '$ZFS_DS_ROOT' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_ROOT"

info "Creating '$ZFS_DS_NIX' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_NIX"

info "Disabling access time setting for '$ZFS_DS_NIX' ZFS dataset ..."
zfs set atime=off "$ZFS_DS_NIX"

info "Creating '$ZFS_DS_PERSIST' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_PERSIST"

info "Permit ZFS auto-snapshots on ${ZFS_SAFE}/* datasets ..."
zfs set com.sun:auto-snapshot=true "$ZFS_DS_PERSIST"

info "Configuring extended attributes setting for '$ZFS_DS_ROOT' ZFS dataset ..."
zfs set xattr=sa "$ZFS_DS_ROOT"

info "Configuring access control list setting for '$ZFS_DS_ROOT' ZFS dataset ..."
zfs set acltype=posixacl "$ZFS_DS_ROOT"

info "Creating '$ZFS_BLANK_SNAPSHOT' ZFS snapshot ..."
zfs snapshot "$ZFS_BLANK_SNAPSHOT"

info "Mounting '$ZFS_DS_ROOT' to /mnt ..."
mount -t zfs "$ZFS_DS_ROOT" /mnt

info "Mounting '$DISK_PART_BOOT' to /mnt/boot ..."
mkdir /mnt/boot
mount -t vfat "$DISK_PART_BOOT" /mnt/boot

info "Mounting '$ZFS_DS_NIX' to /mnt/nix ..."
mkdir /mnt/nix
mount -t zfs "$ZFS_DS_NIX" /mnt/nix

info "Mounting '$ZFS_DS_PERSIST' to /mnt/persist ..."
mkdir /mnt/persist
mount -t zfs "$ZFS_DS_PERSIST" /mnt/persist

info "Generating NixOS configuration (/mnt/etc/nixos/*.nix) ..."
nixos-generate-config --root /mnt

info "Moving password to installation ..."
mkdir -p /mnt/persist/etc/users
mkdir -p /etc/users
mv /tmp/josh /mnt/persist/etc/users/josh
cp /mnt/persist/etc/users/josh /etc/users/josh

info "Cloning NixOS configuration to /mnt/persist/etc/nixos/ ..."
mkdir -p /mnt/persist/etc/nixos
cd /mnt/persist/etc/nixos
git init
git remote add origin https://github.com/joshvanl/nixos.git
git pull origin main
cd -
cp /mnt/persist/etc/nixos/configuration.nix /mnt/etc/nixos/.

info "Appending machine-specific properties to hardware-configuration.nix ..."
HARDWARE_CONFIG=$(mktemp)
cat <<CONFIG > "$HARDWARE_CONFIG"
  boot.zfs.devNodes = "/dev/disk/by-label/$ZFS_POOL";
CONFIG
sed -i "\$e cat $HARDWARE_CONFIG" /mnt/etc/nixos/hardware-configuration.nix

info "Copying generated hardware-configuration.nix to /mnt/persist/etc/nixos/ ..."
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/persist/etc/nixos/

info "Replacing /mnt/etc/nixos with /mnt/persist/etc/nixos ..."
rm -r /mnt/etc/nixos
cp -r /mnt/persist/etc/nixos /mnt/etc/nixos

info "system linking /mnt/persist to ensure passward is captured in nix install ..."
ln -s /mnt/persist /persist

info "system linking host.nix to hostname configuration ..."
ln -s /mnt/etc/nixos/hosts/${HOSTNAME}.nix /mnt/etc/nixos/hosts/host.nix

info "Adding nixos-unstable channel ..."
nix-channel --add https://nixos.org/channels/nixos-unstable nixos

info "Updating nixos channels ..."
nix-channel --update

info "Installing NixOS to /mnt ..."
nixos-install --no-root-passwd

info "Done. Please run 'sudo ./scripts/post-install.sh' once rebooted into system ..."
