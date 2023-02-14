{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.dev-python;
in
{
  options.dev-python = {
    enable = mkEnableOption "josh dev-python";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      python3
    ];
  };
}
