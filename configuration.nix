{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration-zfs.nix
      <home-manager/nixos>
      ./programs.nix
      ./yubikey.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS boot settings
  boot.supportedFilesystems = [ "zfs " ];
  boot.zfs.devNodes = "/dev/";

  networking.hostName = "thistle";
  networking.hostId = "94ec2b8d";
  networking.wireless.userControlled.enable = false;

  # ZFS maintenance settings
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.pools = [ "rpool" ];

  # Set your time zone.
  time.timeZone = "Europe/London";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.enp2s0f0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  };

  fonts.fonts = with pkgs; [
    powerline-fonts
  ];

  users.defaultUserShell = pkgs.zsh;
  users.users.josh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  home-manager.users.josh = { pkgs, ... }: {
    home.packages = [ ];
    programs.bash.enable = true;
  };
  nix.allowedUsers = [ "root" "josh"];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      mako # notification daemon
      alacritty
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      home-manager
      feh
    ];
  };
  xdg.portal.wlr.enable = true; # Enable screen sharing.
  console.useXkbConfig = true;


  environment = {
    etc = {
      "sway/config".source = ./dotfiles/.config/sway/config;
    };
  };
  environment.sessionVariables = rec {
    XDG_DATA_HOME = "/etc/nixos/dotfiles";
  };

  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.caps2esc ];
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };

  system.stateVersion = "nixos";
}
