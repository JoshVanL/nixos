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
      go-jwt
      step-cli
      (mkIf config.me.programs.git.enable git-crypt)
      age
    ];
  };
}
