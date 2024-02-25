{ pkgs, lib, config, ... }:
with lib;

{
  me = {
    machineName = "thistle";
    username = "josh";
    system = "x86_64-linux";
    roles.assume = [
      "josh"
      "sshingress"
      "nixsub"
      "mediaserver"
      "acme"
      "dev"
      "securityserver"
      "cacheserver"
    ];
    base.boot = {
      loader = "systemd-boot";
      initrd.availableKernelModules = [ "ehci_pci" "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" "r8169" ];
    };
    networking = {
      interfaces = [ "enp1s0" "enp2s0f0" "wlan0" ];
      wireguard = config.me.security.joshvanl.wireguard.uk_hop_thistle;
    };
  };

  specialisation = {
    transmit = {
      inheritParentConfig = true;
      configuration = {
        me.roles.media.transmit = true;
      };
    };
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
