{ lib, config, ... }:
with lib;
let
  cfg = config.me.base.parallels;
  prl-tools = config.hardware.parallels.package;

in {
  options.me.base.parallels = {
    enable = mkEnableOption "Enable Parallels support on machine.";
  };

  config = mkIf cfg.enable {
    hardware.parallels.enable = true;
    nixpkgs.config.allowUnfreePredicate = pkg: (lib.getName pkg) == "prl-tools";

    home-manager.users.${config.me.username} = {
      systemd.user.services.prlcp = {
        Unit = {
          Description = "Parallels Copy & Paste Service";
          PartOf = ["graphical-session.target"];
        };
        Install.WantedBy = ["graphical-session.target"];
        Service = {
          Environment = [ "DISPLAY=:0" ];
          Type = "simple";
          ExecStart = [ "${prl-tools}/bin/prlcp" ];
        };
      };
    };
  };
}
