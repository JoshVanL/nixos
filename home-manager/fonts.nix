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

    ".local/share/fonts/System San Francisco Display Regular.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Regular.ttf";
        hash = "sha256-I2qtX7ECyTDw43KedPWvuIpkYbhd/tnaJfAmM0fS2EM=";
      };
    };
    ".local/share/fonts/System San Francisco Display Bold.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Bold.ttf";
        hash = "sha256-CSJpmWjWh25vSWKVouoy8moNIHViIg5tZh9Db/QThyA=";
      };
    };
    ".local/share/fonts/System San Francisco Display Thin.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Thin.ttf";
        hash = "sha256-ihAn79gPjVC7uxMLI3Ht78nZjL/hz5zEhP9O7rdVjWI=";
      };
    };
    ".local/share/fonts/System San Francisco Display Ultralight.ttf" = {
      source = pkgs.fetchurl {
        url = "https://github.com/JoshVanL/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Ultralight.ttf";
        hash = "sha256-fiOPwPIWFUUWu0Pj4WoRvajifuDJyUeLbJvpCSMiHmY=";
      };
    };
  };
}
