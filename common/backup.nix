{ pkgs, ... }:

{
  nixpkgs.config.packageOverrides = super: {
    zfs_uploader = pkgs.callPackage /keep/etc/nixos/nixpkgs/zfs_uploader {
      python3 = pkgs.python3;
      python3Packages = pkgs.python3Packages;
    };
  };

  environment.systemPackages = with pkgs; [
    zfs_uploader
  ];

  systemd.tmpfiles.rules = [
    "d /keep/etc/zfs_uploader 0755 josh wheel - -"
    "d /persist/etc/zfs_uploader 0755 josh wheel - -"
  ];

  systemd.services.zfs_uploader = {
    enable = true;
    description = "ZFS snapshot to S3 uploader";
    wants = [ "network-online.target" ];
    serviceConfig = {
      Environment = "\"PYTHONUNBUFFERED=1\" \"PATH=/run/current-system/sw/bin\"";
      ExecStart = "${pkgs.zfs_uploader}/bin/zfsup --config-path /persist/etc/zfs_uploader/config.cfg backup";
      Restart = "on-failure";
      WorkingDirectory = "/keep/etc/zfs_uploader";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
