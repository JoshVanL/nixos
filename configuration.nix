{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration-zfs.nix
      ./yubikey.nix
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS boot settings
  boot.supportedFilesystems = [ "zfs " ];
  boot.zfs.devNodes = "/dev/";

  networking = {
    hostName = "thistle";
    hostId   = "94ec2b8d";
    useDHCP  = false;
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };

    networkmanager.enable = true;
    firewall.enable = false;
    wireless.userControlled.enable = false;

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  # ZFS maintenance settings
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.pools = [ "rpool" ];

  # Set your time zone.
  time.timeZone = "Europe/London";

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

  nix = {
    allowedUsers = [ "root" "josh"];
    extraOptions = ''
      experimental-features = nix-command
    '';
  };

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
      feh
    ];
  };
  xdg.portal.wlr.enable = true; # Enable screen sharing.
  console.useXkbConfig = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;


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

  # setup .config system link on user login
  system.userActivationScripts.linkConfigToEtc.text = ''
    if [[ ! -h "$HOME/.config" ]]; then
      ln -s "/etc/nixos/dotfiles/.config" "$HOME/.config"
    fi
  '';

  system.stateVersion = "nixos";

  environment.systemPackages = with pkgs; [
    git
    vim_configurable
    wget
    firefox
    termite
    alacritty
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    lxappearance
    cryptsetup
    #go
    kubectl
    yubikey-personalization
    yubikey-manager
    pinentry-curses
    home-manager
    killall
  ];
}
