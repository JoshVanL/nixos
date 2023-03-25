{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.kube;

in {
  options.me.dev.kube = {
    enable = mkEnableOption "dev.kube";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username} = {
      home = {
        packages = with pkgs; [
          kubectl
          kind
          helm
          cmctl
          dapr-cli
          kubernetes-controller-tools
        ];
        file.".config/oh-my-zsh/themes/kubectl.zsh".source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/oh-my-zsh-custom/raw/main/kubectl.zsh";
          hash = "sha256-+jKuFzhFLv+fb76qTMiwFQqa7KTyU/diJLzcsOYRo+o=";
        };
      };

      programs.zsh.shellAliases = mkIf config.me.programs.zsh.enable {
        kc = "kubectl";
        kg = "kubectl get";
        wkc  = "watch -n 0.2 kubectl";
        kcw  = "watch -n 0.2 kubectl";
        kwc  = "watch -n 0.2 kubectl";
        kcc  = "kind create cluster";
        kdc  = "kind delete cluster";
      };
    };
  };
}
