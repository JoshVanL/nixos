{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.networking.nginx;

in {
  options.me.networking.nginx = {};

  config = {
    services.nginx = {
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
    };
  };
}
