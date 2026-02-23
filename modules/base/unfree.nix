{ lib, config, ... }:
with lib;

{
  options.me.nixpkgs.allowedUnfree = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "Package names (lib.getName) allowed even if unfree.";
  };

  config.nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) config.me.nixpkgs.allowedUnfree;
}
