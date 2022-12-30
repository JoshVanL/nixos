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
      init = {
        defaultBranch = "main";
      };
    };
  };
}
