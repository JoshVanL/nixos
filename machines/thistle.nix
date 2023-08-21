{ pkgs, lib, config, ... }:
with lib;

{
  me = {
    machineName = "thistle";
    username = "josh";
    system = "x86_64-linux";
    roles.assume = [ "josh" "sshingress" "nixsub" "mediaserver" "acme" "dev" ];
    base.boot = {
      loader = "systemd-boot";
      initrd.availableKernelModules = [ "ehci_pci" "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" "r8169" ];
    };
    networking = {
      interfaces = [ "enp1s0" "enp2s0f0" "wlan0" ];
      wireguard = config.me.security.joshvanl.wireguard.uk;
    };
    window-manager = {
      enable = true;
      fontsize = 10;
      xrandrArgs = "--output DP-1 --mode 3840x2160 --rate 120";
      naturalScrolling = true;
    };
  };

  specialisation = {
    vpn-none = {
      inheritParentConfig = true;
      configuration = {
        me.networking.tailscale.vpn.enable = mkForce false;
      };
    };
    vpn-tailscale = {
      inheritParentConfig = true;
      configuration = {
        me.networking.tailscale.vpn = {
          enable = true;
          exitNode = "burgundy";
        };
        me.networking.wireguard.enable = mkForce false;
      };
    };
  };
}
