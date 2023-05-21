{ lib, pkgs, config, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/London";
  services.ntp.enable = true;

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
      ${config.me.base.username} = {
        isNormalUser = true;
        uid = 1000;
        createHome = true;
        home = "/home/${config.me.base.username}";
        group = "users";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
        passwordFile = "/keep/etc/users/${config.me.base.username}";
      };
      root = {
        hashedPassword = "!";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${config.me.base.username}/.cache 0755 ${config.me.base.username} wheel - -"
    "d /home/${config.me.base.username}/.config 0755 ${config.me.base.username} wheel - -"
    "d /keep/etc/users 0700 root root - -"
  ];

  home-manager.users.${config.me.base.username}.home = {
    stateVersion = "22.11";
    packages = with pkgs; [
      killall
      htop
    ];
  };
}
