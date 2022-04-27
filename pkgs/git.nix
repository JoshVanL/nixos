{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"
  ];

  home-manager.users.josh = { pkgs, ... }: {
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
  };
}
