{ lib, config, ... }:
with lib;
let
  cfg = config.me.base.parallels;

in {
  options.me.base.parallels = {
    enable = mkEnableOption "Enable Parallels support on machine.";
  };

  config = mkIf cfg.enable {
    hardware.parallels.enable = true;
    nixpkgs.config.allowUnfreePredicate = pkg: (lib.getName pkg) == "prl-tools";

    systemd.user.services.prlcp = {
      enable = true;
      wantedBy = mkForce [ "default.target" ];
      serviceConfig = {
        Environment = [ "DISPLAY=:0" ];
        Restart = mkForce "always";
        RestartSec = mkForce "5s";
      };
    };
  };
}
