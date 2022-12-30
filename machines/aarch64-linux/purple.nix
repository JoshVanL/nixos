{ config, pkgs, lib, modulesPath, ... }: {

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    interfaces.enp0s5.useDHCP = true;
    hostName = "purple";
    hostId = "deadbeef";
  };

  services.josh = {
    docker.enable = true;
    tailscale.enable = true;
    yubikey.enable = true;
    i3 = {
      enable = true;
      xrandr = "--output Virtual-1 --mode 4096x2160 --output Virtual-2 --off";
    };
  };

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "prl-tools" ];
    allowUnsupportedSystem = true;
  };

  hardware.parallels.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    kubectl
    kind
    helm
    cmctl
    python3
    imagemagick
    google-cloud-sdk
    go-jwt
    envsubst
    postgresql
    step-cli
    git-crypt
    age
    terraform
    dive
    vcert
    protobuf
    go-protobuf
    go-protobuf-grpc
    gomarkdoc
    paranoia
  ];
}
