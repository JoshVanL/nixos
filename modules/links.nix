{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.josh.links;
in {
  options.services.josh.links = {
    enable = mkEnableOption "links";
  };

  config = mkIf cfg.enable {
    environment.pathsToLink = [ "/share/zsh/site-functions" ];

    systemd.tmpfiles.rules = [
      # /persist to maintain.
      "d /persist/home           0755 josh wheel - -"
      "d /keep/home/go           0755 josh wheel - -"
      "d /keep/home/downloads    0755 josh wheel - -"
      "d /persist/home/.mozilla  0755 josh wheel - -"
      "d /persist/home/documents 0755 josh wheel - -"

      "d /persist/home/.config          0755 josh wheel - -"
      "d /persist/home/.config/chromium 0755 josh wheel - -"

      "d /persist/home/.config/Bitwarden        0755 josh wheel - -"
      "d '/persist/home/.config/Bitwarden\ CLI' 0755 josh wheel - -"

      "d /persist/home/.cache          0755 josh wheel - -"
      "d /persist/home/.cache/mozilla  0755 josh wheel - -"
      "d /persist/home/.cache/chromium 0755 josh wheel - -"

      "d /persist/var/lib/tailscale 0755 josh wheel - -"

      "d /persist/home/.ssh 0755 josh wheel - -"

      # Locals to pre-create with correct perms.
      "d /home/josh/.config      0755 josh wheel - -"
      "d /home/josh/.cache       0755 josh wheel - -"
      "d /home/josh/.local       0755 josh wheel - -"
      "d /home/josh/.local/share 0755 josh wheel - -"
      "d /root/.config           0755 root root - -"

      # /etc to save.
      "d  /persist/etc/NetworkManager                     0755 josh wheel - -"
      "L+ /etc/NetworkManager/system-connections          - - - - /persist/etc/NetworkManager/system-connections"
      "L+ /etc/nixos                                      - - - - /keep/etc/nixos"

      # Histories/Caches.
      "R  /home/josh/.zsh_history   - - - -"
      "L+ /home/josh/.zsh_history   - - - - /persist/home/.zsh_history"
      "L+ /home/josh/go             - - - - /keep/home/go"
      "L+ /home/josh/.mozilla       - - - - /persist/home/.mozilla"
      "L+ /home/josh/.cache/mozilla - - - - /persist/home/.cache/mozilla"
      "L+ /home/josh/downloads      - - - - /keep/home/downloads"
      "L+ /home/josh/Downloads      - - - - /home/josh/downloads"
      "L+ /home/josh/documents      - - - - /persist/home/documents"
      "L+ /home/josh/.viminfo       - - - - /persist/home/.viminfo"

      "d  /persist/home/.config/github-copilot 0755 josh wheel - -"
      "L+ /home/josh/.config/github-copilot    - - - - /persist/home/.config/github-copilot"

      "L+ /home/josh/.config/chromium - - - - /persist/home/.config/chromium"
      "L+ /home/josh/.cache/chromium  - - - - /persist/home/.cache/chromium"

      "L+ /home/josh/.config/Bitwarden        - - - - /persist/home/.config/Bitwarden"
      "L+ '/home/josh/.config/Bitwarden\ CLI' - - - - /persist/home/.config/Bitwarden\ CLI"
    ];
  };
}
