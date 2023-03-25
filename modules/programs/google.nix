{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.programs.google;

in {
  options.me.programs.google = {
    enable = mkEnableOption "google";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.cloud-build-local])
      ] ++
        (optional config.me.dev.kube.enable pkgs.gke-gcloud-auth-plugin)
      ;

      home.sessionVariables = {
        USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
      };

      programs.zsh.shellAliases = mkIf config.me.programs.zsh.enable {
        gcil = "gcloud compute instances list";
      };
    };
  };
}
