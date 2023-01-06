{ config, lib, pkgs, ... }:

{
  home.file = {
    ".local/share/fonts/Menlo For Powerline.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/Menlo-for-Powerline/raw/master/Menlo%20for%20Powerline.ttf";
        hash = "sha256-7w3GNnpsxfKxY4UneZ/umtr86jJvuNyD+xEpXmWTkik=";
      };
    };
    ".local/share/fonts/Menlo Bold for Powerline.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/Menlo-for-Powerline/raw/master/Menlo%20Bold%20for%20Powerline.ttf";
        hash = "sha256-Hlpyb7zdy6e5GlFzNOeCJby6KrwmZRmHZYUeKKTBw6I=";
      };
    };
    ".local/share/fonts/Menlo Bold Italic for Powerline.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/Menlo-for-Powerline/raw/master/Menlo%20Bold%20Italic%20for%20Powerline.ttf";
        hash = "sha256-uc/Um0SeIRX45INUl3NkLdl+MWaGqPbkj6TOdZpxrGQ=";
      };
    };
    ".local/share/fonts/Menlo Italic for Powerline.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/Menlo-for-Powerline/raw/master/Menlo%20Italic%20for%20Powerline.ttf";
        hash = "sha256-UXrU2UpylBDtmLWginJnwdJX+LX5q6FBfq5STml9GLg=";
      };
    };
  };
}
