{ lib, pkgs, config, ... }:

{
  # Nix.
  nix = {
    settings = {
      allowed-users       = [ "root" "${config.me.username}"];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings.trusted-users = [ "root" "${config.me.username}" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  system.stateVersion = "22.11";

  environment.etc."nixos".source = "/keep/etc/nixos";

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Language.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Users.
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    users = {
      ${config.me.username} = {
        isNormalUser = true;
        uid = 1000;
        createHome = true;
        home = "/home/${config.me.username}";
        group = "users";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
        passwordFile = "/keep/etc/users/${config.me.username}";
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  home-manager.users.${config.me.username}.home.packages = with pkgs; [
    cryptsetup
    killall
    bat
    zip
    unzip
    ripgrep
    tree
  ];
}
