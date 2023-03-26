{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.acme;

in {
  options.me.networking.acme = {
    enable = mkEnableOption "acme";
    email = mkOption {
      type = types.str;
    };
    dnsProvider = mkOption {
      type = types.enum [ "gcloud" ];
    };
    credentialsFile = mkOption {
      type = types.path;
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = cfg.email;
        dnsProvider = cfg.dnsProvider;
        credentialsFile = cfg.credentialsFile;
      };
    };

    systemd.user.tmpfiles.rules = [
      "d /persist/var/lib/acme 0755 acme acme - -"
    ];

    fileSystems."/var/lib/acme" = { options = [ "bind" ]; device = "/persist/var/lib/acme"; };
  };
}
