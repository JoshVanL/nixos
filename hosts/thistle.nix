{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "thistle";
    hostId   = "94ec2b8d";
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0f0.useDHCP = true;
      wlp3s0.useDHCP = true;
    };
  };
}

