# NixOS Configuration Repository

Multi-machine NixOS flake configuration with role-based modularity, ZFS immutable root, and comprehensive development environments.

## Quick Reference

```bash
# Build and switch (on a configured machine)
sudo nixos-rebuild switch --flake /keep/etc/nixos

# Build without switching
nixos-rebuild build --flake /keep/etc/nixos

# Update flake inputs
nix flake update

# Fresh install
nix run --experimental-features 'nix-command flakes' github:joshvanl/nixos
```

## Repository Structure

```
flake.nix              # Inputs: nixpkgs (nixos-25.11), home-manager, joshvanldwm, nix-serve-ng, xpropdate, nur
machines/              # Per-machine configs (burgundy, thistle, purple, mini)
modules/               # Reusable NixOS modules (~77 files)
  base/                # Boot (ZFS rollback), nix settings, OS, unfree allowlist
  dev/                 # Language environments: go, rust, python, node, c, dotnet, ai, kube, grpc, etc.
  shell/               # zsh (oh-my-zsh), neovim (treesitter, gruvbox, copilot), console
  networking/          # ssh, tailscale, wireguard, acme, nginx, podman, dns, interfaces
  security/            # yubikey (PAM), bitwarden, SSH keys (joshvanl.nix)
  data/                # cache (nix, go, container registry), media (plex, transmission, radarr, sonarr, jackett), zfs_uploader
  roles/               # Role definitions: josh, dev, mediaserver, acme, sshingress, cacheserver, nixsub, img
  wm/                  # X11/DWM, alacritty, ghostty, rofi, fonts, gtk, browser
overlays/              # Package overrides: golang, dapr, claude-code, bitwarden-cli, backblaze-b2
pkgs/                  # Custom packages (~17): ww, paranoia, passenc, gimmi, fehr, myip, imps, zfs_uploader, etc.
lib/                   # Helper functions: nixFiles, defaultImport, dirs
apps/                  # Install & post-install scripts
```

## Architecture & Patterns

### Option Namespace
All custom options live under `config.me.*`:
- `me.machineName`, `me.username`, `me.system` - Machine identity
- `me.roles.assume = [ "josh" "dev" ... ]` - Role assignment (validated for duplicates)
- `me.dev.go.enable`, `me.dev.rust.enable`, etc. - Feature toggles via `mkEnableOption`

### Role System
Machines declare roles in `machines/<name>.nix` via `me.roles.assume`. Each role in `modules/roles/` enables a set of modules. Role module files are auto-discovered.

### ZFS Immutable Root
Root filesystem (`rpool/local/root`) is rolled back to a blank snapshot on every shutdown via `boot.nix`. Persistent data is stored on:
- `/keep` - Machine state, config (e.g., `/keep/etc/nixos`, `/keep/etc/ssh`)
- `/persist` - Backed-up data (home dirs, ACME certs, service state)

Symlinks and bind mounts connect persistent paths into the ephemeral root.

### Home-Manager Integration
Used extensively for per-user packages, shell config, vim plugins, git settings, and session variables. Integrated via NixOS module (not standalone).

### Specialisations
Machines can define specialisations (e.g., `transmit`, `vpn-none`, `vpn-tailscale`, `onthemove`) for runtime-switchable configurations.

## Machines

| Machine | Arch | Type | Key Roles |
|---------|------|------|-----------|
| **thistle** | x86_64 | Server | josh, sshingress, nixsub, mediaserver, acme, dev, securityserver, cacheserver |
| **purple** | aarch64 | Parallels VM | josh, nixsub, dev, img (has WM) |
| **mini** | aarch64 | Parallels VM | josh, dev (has WM, user: notme) |
| **burgundy** | aarch64 | Raspberry Pi 4 | josh (tailscale exit node, wireguard) |

## Conventions

- **No em dashes**: Do not use em dashes (—) in any output, commit messages, or file content. Use commas, parentheses, colons, or separate sentences instead.
- **Commit messages**: `module/path.nix: description` (e.g., `overlays/claude-code.nix: update version to 2.1.63`)
- **Module files**: Match their config path. `modules/dev/go.nix` controls `config.me.dev.go`
- **Aggregators**: Each directory has a `default.nix` that imports all sibling `.nix` files
- **Shell wrappers**: Use `pkgs.writeShellApplication` for custom scripts
- **Persistent state**: Always symlink or bind-mount from `/keep` or `/persist`, never store state on root
- **Overlays**: Override upstream packages with pinned versions and custom build flags

## Key Files

- `modules/security/joshvanl.nix` - SSH public keys, Yubikey IDs, nix cache keys, wireguard endpoints
- `modules/base/boot.nix` - ZFS rollback logic, kernel config, initrd SSH
- `modules/base/nix.nix` - Binary caches, GC, specialisation hooks
- `modules/roles/default.nix` - Role validation and discovery
- `lib/default.nix` - `nixFiles` (list .nix files), `defaultImport`, `dirs` helpers

## Common Tasks

### Adding a new package overlay
1. Create `overlays/<name>.nix` with the override
2. It's auto-imported by `overlays/default.nix` (uses `lib.nixFiles`)

### Adding a new dev module
1. Create `modules/dev/<lang>.nix` with `mkEnableOption` and package list
2. Auto-imported by `modules/dev/default.nix`
3. Enable it from the relevant role in `modules/roles/dev.nix`

### Adding a new machine
1. Create `machines/<name>.nix` with `me.machineName`, `me.system`, `me.username`, `me.roles.assume`
2. Add `machines/<name>-hardware.nix` for hardware-specific config
3. Machine is auto-discovered by `machines/default.nix`

### Adding a new custom package
1. Create `pkgs/<name>/default.nix` (or `pkgs/<name>.nix`)
2. Auto-imported by `pkgs/default.nix` using `lib.dirs` or `lib.nixFiles`
