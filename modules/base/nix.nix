{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.nix;

in {
  options.me.base.nix = {
    substituters = mkOption {
      type = types.listOf types.str;
      default = [ "https://cache.nixos.org" ];
      description = ''
        A list of Nix binary caches to use.
      '';
    };
  };

  config = {
    nix = {
      settings = {
        allowed-users = [ "root" "${config.me.base.username}"];
        auto-optimise-store = true;
        substituters = cfg.substituters;
      };


      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      settings.trusted-users = [ "root" "${config.me.base.username}" ];

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
    system.stateVersion = "22.11";

    environment.etc."nixos".source = "/keep/etc/nixos";

    nixpkgs.config.allowUnsupportedSystem = true;
  };
}
