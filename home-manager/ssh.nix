{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    userKnownHostsFile = "/persist/home/.ssh/known_hosts";
  };
}
