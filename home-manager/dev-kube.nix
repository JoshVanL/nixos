{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.dev-kube;
in
{
  options.dev-kube = {
    enable = mkEnableOption "josh dev-kube";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kubectl
      kind
      helm
      cmctl
      dapr-cli
      kubernetes-controller-tools
    ];
  };
}
