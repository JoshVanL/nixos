{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.image;

  screenSH = pkgs.writeShellApplication {
    name = "screen";
    runtimeInputs = with pkgs; [ xclip scrot coreutils ];
    text = ''
      dir="$HOME/screenshots"
      file="$dir/$(date +%Y-%m-%d-%H%M%S).png"
      mkdir -p "$dir"
      scrot -shole - \
        | tee "$file" \
        | xclip -selection clipboard -target image/png
      echo "$file"
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
