{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    userKnownHostsFile = "/persist/home/.ssh/known_hosts";
  };
}
