{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.cloud;

in {
  options.me.dev.cloud = {
    enable = mkEnableOption "dev.cloud";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /keep/home/.aws 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.aws - - - - /keep/home/.aws"
    ];

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        awscli2
        (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.cloud-build-local])
      ] ++
        (optional config.me.dev.kube.enable pkgs.gke-gcloud-auth-plugin)
      ;

      home.sessionVariables = {
        USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
      };

      programs.zsh.shellGlobalAliases = {
        gcil = "gcloud compute instances list";
      };
    };
  };
}
