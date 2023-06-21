{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.console;


in {
  options.me.shell.console = {};

  config = {
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
  };
}
