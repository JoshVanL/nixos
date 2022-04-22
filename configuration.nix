{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./yubikey.nix
      <home-manager/nixos>
    ];

  nix.nixPath =
    [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/persist/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

  # Clense with fire.
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

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

  systemd.tmpfiles.rules = [
      "d /home/josh/.config 0755 josh wheel - -"
      "d /root/.config 0755 root root - -"

      "L /root/.config/alacritty       - - - - /persist/etc/nixos/dotfiles/.config/alacritty"
      "L /home/josh/.config/alacritty  - - - - /persist/etc/nixos/dotfiles/.config/alacritty"
      "L /root/.config/nixpkgs         - - - - /persist/etc/nixos/dotfiles/nixpkgs"
      "L /home/josh/.config/nixpkgs    - - - - /persist/etc/nixos/dotfiles/nixpkgs"
      "L /root/.config/oh-my-zsh       - - - - /persist/etc/nixos/dotfiles/.config/oh-my-zsh"
      "L /home/josh/.config/oh-my-zsh  - - - - /persist/etc/nixos/dotfiles/.config/oh-my-zsh"
      "L /root/.local/share/fonts      - - - - /persist/etc/nixos/dotfiles/fonts"
      "L /home/josh/.local/share/fonts - - - - /persist/etc/nixos/dotfiles/fonts"
  ];

  fonts.fonts = with pkgs; [
    powerline-fonts
  ];

  system.stateVersion = "nixos";

  environment = {
    etc = {
      "sway/config".source = ./dotfiles/.config/sway/config;
    };
    sessionVariables = rec {
      XDG_DATA_HOME = "~/.local/share/fonts";
    };
    systemPackages = with pkgs; [
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
      home-manager
      killall
    ];
  };
}
