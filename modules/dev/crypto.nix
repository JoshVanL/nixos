{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.crypto;

in {
  options.me.dev.crypto = {
    enable = mkEnableOption "dev.crypto";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.base.username}.home.packages = with pkgs; [
      openssl
      go-jwt
      step-cli
      (mkIf config.me.dev.git.enable git-crypt)
      age
    ];
  };
}
