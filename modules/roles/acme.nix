{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

in {
  config = mkIf (elem "acme" cfg.assume) {
    me.networking.acme = {
      enable = true;
      dnsProvider = "gcloud";
      email = "me@joshvanl.dev";
      credentialsFile = "/persist/etc/joshvanl/dns/acme/credentials.secret";
    };
  };
}
