{ pkgs, lib, config, ... }: {
  me = {
    machineName = "burgundy";
    username = "josh";
    system = "aarch64-linux";
    #roles.assume = [ "josh" "sshingress" "securityserver" "cacheserver" "acme" ];
    #roles.assume = [ "josh" "sshingress" "securityserver" "acme" ];
    roles.assume = [ "josh" ];
    base = {
      nix = {
        extraSubstituters = [ "http://nixcache.joshvanl.dev" ];
        gc.automatic = false;
      };
      boot = {
        loader = "systemd-boot";
        #kernelPackages = pkgs.linuxPackages_rpi4;
        # ttyAMA0 is the serial console broken out to the GPIO
        #kernelParams = [
        #  "nohibernate"
        #  "8250.nr_uarts=1"
        #  "console=ttyAMA0,115200"
        #  "console=tty1"
        #];
        initrd.availableKernelModules = [ "usbhid" "usb_storage" "smsc95xx" "usbnet" "vc4" "pcie_brcmstb" "reset-raspberrypi" ];
        # Enable so we can build other machines for the cache.
        #emulatedSystems = [ "x86_64-linux" ];
      };
    };
    networking = {
      interfaces = [ "eth0" ];
      tailscale.ingress = {
        enable = true;
        isExitNode = true;
      };
      wireguard = config.me.security.joshvanl.wireguard.uk_hop;
    };
  };
}
