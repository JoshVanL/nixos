{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.image;

  screenSH = pkgs.writeShellApplication {
    name = "screen";
    runtimeInputs = with pkgs; [ xclip scrot coreutils ];
    text = ''
      dir="$HOME/screenshots"
      mkdir -p "$dir"
      scrot -shole - \
        | tee "$dir/$(date +%Y-%m-%d-%H%M%S).png" \
        | xclip -selection clipboard -target image/png
    '';
  };

in {
  options.me.dev.image = {
    enable = mkEnableOption "dev.image";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      imagemagick
      imv
      feh
      gthumb
      scrot
      screenSH
    ];
  };
}
