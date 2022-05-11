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
}
