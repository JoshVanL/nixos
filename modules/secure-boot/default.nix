{ config, lib, pkgs, ... }:

let
  bootspecSecurebootSrc = builtins.fetchGit {
    url = "https://github.com/DeterminateSystems/bootspec-secureboot.git";
    ref = "main";
  };
in
{
  imports = [ "${bootspecSecurebootSrc}/nixos-module.nix" ];
  nixpkgs.overlays = [
    (final: prev: {
      bootspec-secureboot = import bootspecSecurebootSrc;
    })
  ];

  #boot.loader.secureboot = {
  #  enable = true;
  #  signingKeyPath  = "/persist/etc/secure-boot/db.key";
  #  signingCertPath = "/persist/etc/secure-boot/db.crt";
  #};
}
