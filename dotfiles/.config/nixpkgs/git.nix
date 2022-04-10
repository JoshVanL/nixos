{ config, pkgs, ...}:

{
  programs.git = {
    enable = true;
    userEmail = "vleeuwenjoshua@gmail.com";
    userName  = "joshvanl";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };
}
