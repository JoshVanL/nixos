{ lib, pkgs, config, ... }:

{
  # Set your time zone.
  #time.timeZone = "Europe/London";
  #time.timeZone = "America/Los_Angeles";
  time.timeZone = "America/Buenos_Aires";

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
        extraGroups = [ "wheel" "video" ];
        hashedPasswordFile = "/keep/etc/users/${config.me.username}";
      };
      root.hashedPassword = "!";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${config.me.username}/.cache 0755 ${config.me.username} wheel - -"
    "d /home/${config.me.username}/.config 0755 ${config.me.username} wheel - -"
    "d /keep/etc/users 0700 root root - -"
  ];

  home-manager.users.${config.me.username}.home = {
    stateVersion = config.system.stateVersion;
    packages = with pkgs; [
      killall
      htop
      lsof
    ];
  };
}
