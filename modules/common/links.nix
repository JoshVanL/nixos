{ config, lib, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
      # Host specific nix.
      "L+ /keep/etc/nixos/hosts/host.nix - - - - /keep/etc/nixos/hosts/%H.nix"

      # /persist to maintain.
      "d /persist/home           0755 josh wheel - -"
      "d /keep/home/go           0755 josh wheel - -"
      "d /keep/home/downloads    0755 josh wheel - -"
      "d /keep/var/lib/docker    0755 josh wheel - -"
      "d /persist/home/.mozilla  0755 josh wheel - -"
      "d /persist/home/documents 0755 josh wheel - -"

      "d /persist/home/.config          0755 josh wheel - -"
      "d /persist/home/.config/chromium 0755 josh wheel - -"
      "d /persist/home/.docker          0755 josh wheel - -"

      "d /persist/home/.config/Bitwarden        0755 josh wheel - -"
      "d '/persist/home/.config/Bitwarden\ CLI' 0755 josh wheel - -"

      "d /persist/home/.cache          0755 josh wheel - -"
      "d /persist/home/.cache/mozilla  0755 josh wheel - -"
      "d /persist/home/.cache/chromium 0755 josh wheel - -"

      "d /persist/var/lib/tailscale 0755 josh wheel - -"

      # Locals to pre-create with correct perms.
      "d /home/josh/.config      0755 josh wheel - -"
      "d /home/josh/.cache       0755 josh wheel - -"
      "d /home/josh/.local       0755 josh wheel - -"
      "d /home/josh/.local/share 0755 josh wheel - -"
      "d /root/.config           0755 root root - -"

      # /etc to save.
      "d  /persist/etc/NetworkManager/system-connections  0755 josh wheel - -"
      "L+ /etc/NetworkManager/system-connections          - - - - /persist/etc/NetworkManager/system-connections"

      # Histories/Caches.
      "R  /home/josh/.zsh_history   - - - -"
      "L+ /home/josh/.zsh_history   - - - - /persist/home/.zsh_history"
      "L+ /home/josh/go             - - - - /keep/home/go"
      "L+ /home/josh/.mozilla       - - - - /persist/home/.mozilla"
      "L+ /home/josh/.cache/mozilla - - - - /persist/home/.cache/mozilla"
      "L+ /home/josh/downloads      - - - - /keep/home/downloads"
      "L+ /home/josh/documents      - - - - /persist/home/documents"
      "L+ /home/josh/.docker        - - - - /persist/home/.docker"
      "L+ /home/josh/.viminfo       - - - - /persist/home/.viminfo"

      "d  /persist/home/.config/github-copilot 0755 josh wheel - -"
      "L+ /home/josh/.config/github-copilot    - - - - /persist/home/.config/github-copilot"

      "L+ /home/josh/.config/chromium - - - - /persist/home/.config/chromium"
      "L+ /home/josh/.cache/chromium  - - - - /persist/home/.cache/chromium"

      "L+ /home/josh/.config/Bitwarden        - - - - /persist/home/.config/Bitwarden"
      "L+ '/home/josh/.config/Bitwarden\ CLI' - - - - /persist/home/.config/Bitwarden\ CLI"

      "L+ /var/lib/docker - - - - /keep/var/lib/docker"
  ];
}
