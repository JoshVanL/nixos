{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.networking.interfaces;

  myIPSH = pkgs.writeShellApplication {
    name = "myip";
    runtimeInputs = with pkgs; [ curl ];
    text = ''
      curl -L http://ipconfig.me
    '';
  };

in {
  options.me.networking.interfaces = {
    intf = mkOption { };
  };

  config = {
    networking.interfaces = cfg.intf;
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      fast-cli
      wget
      myIPSH
    ];
  };
}
