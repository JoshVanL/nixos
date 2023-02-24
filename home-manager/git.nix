{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "me@joshvanl.dev";
    userName  = "joshvanl";
    ignores = [
      "*.swp"
      ".envrc"
    ];
    extraConfig = {
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
      init = {
        defaultBranch = "main";
      };
    };
  };
}
