{ lib }:

with lib;

# Extended from https://gist.github.com/mx00s/ea2462a3fe6fdaa65692fe7ee824de3e
#
# NixOS install script synthesized from:
# - Erase Your Darlings (https://grahamc.com/blog/erase-your-darlings)
# - ZFS Datasets for NixOS (https://grahamc.com/blog/nixos-on-zfs)
# - NixOS Manual (https://nixos.org/nixos/manual/)

let
  zfsPool = "rpool";
  zfsLocal = "${zfsPool}/local";
  zfsDSRoot = "${zfsLocal}/root";
  zfsDSNix = "${zfsLocal}/nix";
  zfsDSKeep = "${zfsLocal}/keep";
  zfsDSSafe = "${zfsPool}/safe";
  zfsDSPersist = "${zfsDSSafe}/persist";
  zfsBlankSnapshot = "${zfsDSRoot}@blank";

  raspPiFirmwareSrc = {
    version = "1.35";
    hash = "sha256-PqFta8T48SJSetaoTA/oStgNhf1DqGjZnDYK2ek9P24=";
  };

  install = system:
  let
    pkgs = pkgsys system;
    raspPiFirmware = with raspPiFirmwareSrc; pkgs.fetchurl {
      inherit hash;
      url = "https://github.com/pftf/RPi4/releases/download/v${version}/RPi4_UEFI_Firmware_v${version}.zip";
    };
  in pkgs.writeShellApplication {
    name = "install.sh";
    runtimeInputs = with pkgs; [
      coreutils
      util-linux
      mkpasswd
      nix
      git
      zfs
      parted
      systemdMinimal
    ];
    text = ''
      ${loggerFuncsString}
      ${mustBeRootString}

      TMPDIR=$(mktemp -d)
      trap 'rm -rf -- "$TMPDIR"' EXIT

      PS3="> "
      declare -A USERNAMES_MAP=(${usernamesBashMap})

      NIXOS_REPO="''${NIXOS_REPO:-joshvanl/nixos}"
      COMMIT="''${COMMIT:-main}"

      info "Running NixOS install from ''${NIXOS_REPO}@''${COMMIT}"
      err "!! WARNING: This will erase the contents of the chosen disk. !!"
      info "######################"

      MACHINE=""
      AVAILABLE_MACHINES=(${sysMachines system})
      info "All machines in configuration: [${concatStringsSep ", " allMachines}]"
      info "All machines maching this system (${system}): [''${AVAILABLE_MACHINES[*]}]"
      ask "Select a machine to install:"
      select machine in "''${AVAILABLE_MACHINES[@]}"
      do
        if [[ -z "$machine" ]]; then
          err "Invalid machine selection."
          continue
        fi
        MACHINE=$machine
        break
      done
      USERNAME="''${USERNAMES_MAP[$MACHINE]}"
      info "Installing machine '$MACHINE' with user '$USERNAME'."

      mapfile -t AVAILABLE_DISKS < <(lsblk -d | tail -n+2 | cut -d" " -f1)
      DISK=""
      ask "Select a disk to format and install:"
      select d in "''${AVAILABLE_DISKS[@]}"
      do
        if [[ -z "$d" ]]; then
          err "Invalid disk selection."
          continue
        fi
        DISK=$d
        break
      done
      DISK_PATH="/dev/$DISK"
      info "Installing to '$DISK_PATH'."

      PARTITION_PREFIX=""
      ask "Select a partition prefix."
      ask "Generally, for '/dev/nvmeX' disks use 'p', and '/dev/sdX' disks use nothing."
      if [[ $DISK != nvme* ]]; then
        ask "You probably want <no prefix> (1)."
      else
        ask "You probably want 'p' (2)."
      fi
      select p in "<no prefix>" "p"
      do
        if [[ -z "$p" ]]; then
          err "Invalid selection."
          continue
        fi
        if [[ $p == "<no prefix>" ]]; then
          p=""
        fi
        PARTITION_PREFIX=$p
        break
      done
      DISK_PART_ROOT="''${DISK_PATH}''${PARTITION_PREFIX}1"
      DISK_PART_BOOT="''${DISK_PATH}''${PARTITION_PREFIX}2"
      info "Using partition prefix '$PARTITION_PREFIX'."

      ask "You will install the NixOS machine '$MACHINE' with the user '$USERNAME', on the disk '$DISK_PATH'."
      while true; do
        read -r -p "Continue? [y/n] " yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) err "Cancelled."; exit 1;;
          * ) err "Please answer yes or no.";;
        esac
      done

      ask "Enter password for '$USERNAME' user ..."
      mkpasswd -m sha-512 | tr -d "\n\r" > "$TMPDIR/$USERNAME"

      info "Partitioning disk '$DISK_PATH' ..."
      parted "$DISK_PATH" -- mklabel gpt
      parted "$DISK_PATH" -- mkpart primary 513MiB 100%
      parted "$DISK_PATH" -- mkpart ESP fat32 1MiB 513MiB
      parted "$DISK_PATH" -- set 2 boot on

      info "Formatting boot partition ..."
      mkfs.fat -F 32 -n boot "$DISK_PART_BOOT"

      info "Creating '${zfsPool}' ZFS pool for '$DISK_PART_ROOT' ..."
      zpool create -f \
        -o ashift=12 \
        -o autotrim=on \
        -O canmount=off \
        -O mountpoint=none \
        -O acltype=posixacl \
        -O compression=lz4 \
        -O dnodesize=auto \
        -O relatime=on \
        -O normalization=formD \
        -O xattr=sa \
        -O encryption=aes-256-gcm \
        -O keylocation=prompt \
        -O keyformat=passphrase "${zfsPool}" "$DISK_PART_ROOT"

      info "Creating '${zfsDSRoot}' ZFS dataset ..."
      zfs create -p -o canmount=on -o mountpoint=legacy "${zfsDSRoot}"

      info "Creating '${zfsDSNix}' ZFS dataset ..."
      zfs create -p -o canmount=on -o mountpoint=legacy "${zfsDSNix}"

      info "Disabling access time setting for '${zfsDSNix}' ZFS dataset ..."
      zfs set atime=off "${zfsDSNix}"

      info "Creating '${zfsDSKeep}' ZFS dataset ..."
      zfs create -p -o canmount=on -o mountpoint=legacy "${zfsDSKeep}"

      info "Creating '${zfsDSPersist}' ZFS dataset ..."
      zfs create -p -o canmount=on -o mountpoint=legacy "${zfsDSPersist}"

      info "Permit ZFS auto-snapshots on ${zfsDSSafe}/* datasets ..."
      zfs set com.sun:auto-snapshot=true "${zfsDSPersist}"

      info "Creating '${zfsBlankSnapshot}' ZFS snapshot ..."
      zfs snapshot "${zfsBlankSnapshot}"

      info "Mounting '${zfsDSRoot}' to /mnt ..."
      mkdir -p /mnt
      mount -t zfs "${zfsDSRoot}" /mnt

      info "Mounting '$DISK_PART_BOOT' to /mnt/boot ..."
      mkdir /mnt/boot
      mount -t vfat "$DISK_PART_BOOT" /mnt/boot

      USE_RASP_PI_FIRMWARE=$(nix eval "github:$NIXOS_REPO/${commit-rev}#nixosConfigurations.$MACHINE.options.me.base.boot.raspberryPiFirmware.value" 2&>/dev/null)
      if [[ $USE_RASP_PI_FIRMWARE == "true" ]]; then
        info "Installing Raspberry Pi firmware on /mnt/boot ..."
        cp -r ${raspPiFirmware}/* /mnt/boot
      fi

      info "Mounting '${zfsDSNix}' to /mnt/nix ..."
      mkdir /mnt/nix
      mount -t zfs "${zfsDSNix}" /mnt/nix

      info "Mounting '${zfsDSKeep}' to /mnt/keep ..."
      mkdir /mnt/keep
      mount -t zfs "${zfsDSKeep}" /mnt/keep

      info "Mounting '${zfsDSPersist}' to /mnt/persist ..."
      mkdir /mnt/persist
      mount -t zfs "${zfsDSPersist}" /mnt/persist

      info "Moving password to installation ..."
      mkdir -p /mnt/keep/etc/users
      mkdir -p /etc/users
      mv "$TMPDIR/$USERNAME" "/mnt/keep/etc/users/$USERNAME"
      cp "/mnt/keep/etc/users/$USERNAME" "/etc/users/$USERNAME"

      info "Cloning NixOS configuration to /mnt/keep/etc/nixos/ ..."
      rm -rf /mnt/keep/etc/nixos && mkdir -p /mnt/keep/etc/nixos
      git clone "https://github.com/$NIXOS_REPO" /mnt/keep/etc/nixos

      info "System linking /mnt/keep to ensure passward is captured in nix install ..."
      ln -s /mnt/keep /keep

      info "System linking /mnt/persist to ensure ssh is captured in nix install ..."
      ln -s /mnt/persist /persist

      info "Installing NixOS to /mnt ..."
      NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-install --no-root-passwd --flake "github:$NIXOS_REPO/${commit-rev}#$MACHINE"

      info "Done. Please run 'nix run /etc/nixos#post-install' once rebooted into system ..."
      info "Rebooting ..."
      read -r -p "Press any key to continue ..."
      reboot
    '';
  };

in listToAttrs (map (system:
  nameValuePair "${system}" {
    default = mkApp (install system);
    install = mkApp (install system);
  }
) targetSystems)
