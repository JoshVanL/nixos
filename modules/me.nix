{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me;

in {
  options.me = {
    machineName = mkOption {
      type = types.str;
      description = "The name of the machine.";
    };

    username = mkOption {
      type = types.str;
    };

    system = mkOption {
      type = types.str;
      default = "";
      description = "The architecture and OS of the machine.";
    };
  };

  config = {
    assertions = [{
      assertion = cfg.system == "x86_64-linux" || cfg.system == "aarch64-linux";
      message = "Invalid system: ${cfg.system}. Must be 'x86_64-linux' or 'aarch64-linux'.";
    }];
  };
}
