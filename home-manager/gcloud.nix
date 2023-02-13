{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.gcloud;
in
{
  options.gcloud = {
    enable = mkEnableOption "josh glcoud";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.cloud-build-local])
      gke-gcloud-auth-plugin
    ];
    home.sessionVariables = {
      USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
    };
  };
}
