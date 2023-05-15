{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.programs.alias;

  ffSH = pkgs.writeShellApplication {
    name = "ff";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      fn=''${1:-}
      dir=''${2:-.}
      find "$dir" -type f -iname "*.$fn"
    '';
  };

  grpSH = pkgs.writeShellApplication {
    name = "grp";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      e=''${1:-}
      dir=''${2:-.}
      grep --color=always -irn "$dir" -e "$e"
    '';
  };

in {
  options.me.programs.alias = {};

  config = {
    home-manager.users.${config.me.base.username}.home.packages = [
      ffSH
      grpSH
    ];
  };
}
