{ pkgs, lib, config, ... }:
with lib;

{
  me = {
    machineName = "purple";
    system = "aarch64-linux";
    username = "josh";
    roles.assume = [ "josh" "nixsub" "dev" ];
    base = {
      boot = {
        loader = "systemd-boot";
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
      };
      parallels.enable = true;
    };
    networking = {
      interfaces = [ "enp0s5" ];
      wireguard = config.me.security.joshvanl.wireguard.uk_hop;
      tailscale.vpn.enable = false;
      #tailscale.vpn = {
      #  enable = true;
      #  exitNode = "burgundy";
      #};
    };
    window-manager = {
      enable = true;
      fontsize = 15;
      xrandrArgs = "--output Virtual-1 --mode 4096x2160 --rate 120 --output Virtual-2 --off";
      arrowKeysMap60 = true;
    };
  };

  specialisation = {
    vpn-none = {
      inheritParentConfig = true;
      configuration = {
        me.networking.tailscale.vpn.enable = mkForce false;
        me.networking.wireguard.enable = mkForce false;
      };
    };
    onthemove = {
      inheritParentConfig = true;
      configuration = {
        me.window-manager.fontsize = mkForce 24;
        me.window-manager.arrowKeysMap60 = mkForce false;
      };
    };
    onthemove-vpn-none = {
      inheritParentConfig = true;
      configuration = {
        me.window-manager.fontsize = mkForce 24;
        me.networking.tailscale.vpn.enable = mkForce false;
        me.networking.wireguard.enable = mkForce false;
        me.window-manager.arrowKeysMap60 = mkForce false;
      };
    };
  };
}
