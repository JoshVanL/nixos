{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me;

in {
  options.me = {
    username = mkOption {
      type = types.str;
    };

    system = mkOption {
      type = types.str;
      default = "";
      description = "The architecture and OS of the system to install to.";
    };
  };

  config = {
    assertions = [{
      assertion = cfg.system == "x86_64-linux" || cfg.system == "aarch64-linux";
      message = "Invalid system: ${cfg.system}. Must be 'x86_64-linux' or 'aarch64-linux'.";
    }];
  };
}
