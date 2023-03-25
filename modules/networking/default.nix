{ lib, pkgs, config, ... }:
{
  imports = [
    ./ssh.nix
    ./tailscale.nix
  ];

  systemd.user.tmpfiles.rules = [
    "d /persist/etc/NetworkManager 0755 ${config.me.username} wheel - -"
  ];
  environment.etc."NetworkManager/system-connections".source = "/persist/etc/NetworkManager/system-connections";

  networking = {
    networkmanager.enable = true;
    wireless.userControlled.enable = false;
    useDHCP  = false;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  home-manager.users.${config.me.username}.home.packages = with pkgs; [
    wget
  ];
}
