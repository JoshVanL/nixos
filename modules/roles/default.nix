{ lib, pkgs, config, ... }:
with lib;

let
  cfg = config.me.roles;

  knownRoles = map (name: removeSuffix ".nix" name) (nixFilesNoDefault' ./.);

in {
  imports = (defaultImport ./.);

  options.me.roles = {
    assume = mkOption {
      type = types.listOf (types.enum knownRoles);
      default = [];
      description = "List of machine roles to assume";
    };
  };

  config = {
    assertions = [
      {
        assertion = compareLists compare (unique config.me.roles.assume) config.me.roles.assume == 0;
        message = "Duplicate roles in config.me.roles.assume";
      }
    ];
  };
}
