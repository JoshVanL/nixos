{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.kube;

in {
  options.me.dev.kube = {
    enable = mkEnableOption "dev.kube";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = mkIf config.me.programs.podman.enable [
      # This directory is hardcoded in kind somewhere and is required for it to
      # work but doesn't actually use it...
      "d /lib/modules 0755 ${config.me.base.username} wheel - -"
    ];

    home-manager.users.${config.me.base.username} = {
      home = {
        packages = with pkgs; [
          kubectl
          kubernetes-helm
          cmctl
          dapr-cli
          kubernetes-controller-tools
        ]
        ++ (optional config.me.programs.podman.enable kind)
        ++ (optional config.me.dev.kube.enable pkgs.gke-gcloud-auth-plugin)
        ;

        file.".config/oh-my-zsh/themes/kubectl.zsh".source = pkgs.fetchurl {
          url = "https://github.com/joshvanl/oh-my-zsh-custom/raw/main/kubectl.zsh";
          hash = "sha256-+jKuFzhFLv+fb76qTMiwFQqa7KTyU/diJLzcsOYRo+o=";
        };
      };

      programs.zsh.shellAliases = ({
        kc = "kubectl";
        kg = "kubectl get";
        wkc  = "watch -n 0.2 kubectl";
        kcw  = "watch -n 0.2 kubectl";
        kwc  = "watch -n 0.2 kubectl";
      } // (optionalAttrs config.me.programs.podman.enable {
        kcc  = "kind create cluster";
        kdc  = "kind delete cluster";
      }));
    };
  };
}
