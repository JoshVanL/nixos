{ config, lib, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
      # Host specific nix.
      "L+ /keep/etc/nixos/hosts/host.nix - - - - /keep/etc/nixos/hosts/%H.nix"

      # /persist to maintain.
      "d /persist/home          0755 josh wheel - -"
      "d /keep/home/go       0755 josh wheel - -"
      "d /persist/home/.ssh     0700 josh wheel - -"
      "d /persist/home/.mozilla 0755 josh wheel - -"

      "d /persist/home/.cache         0755 josh wheel - -"
      "d /persist/home/.cache/mozilla 0755 josh wheel - -"

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
      "L+ /home/josh/.ssh           - - - - /persist/home/.ssh"
      "L+ /home/josh/.mozilla       - - - - /persist/home/.mozilla"
      "L+ /home/josh/.cache/mozilla - - - - /persist/home/.cache/mozilla"
  ];
}
