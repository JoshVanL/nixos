{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  # Enable zsh completion from programs built from nixpkgs.
  environment.pathsToLink = [ "/share/zsh/site-functions" ];
  programs.zsh.enableCompletion = true;


  home-manager.users.josh = { pkgs, ... }: {
    home.file = {
      ".config/oh-my-zsh/themes/kubectl.zsh" = {
        source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/oh-my-zsh-custom/raw/main/kubectl.zsh";
          hash = "sha256-+jKuFzhFLv+fb76qTMiwFQqa7KTyU/diJLzcsOYRo+o=";
        };
      };
      ".config/oh-my-zsh/themes/amuse-custom.zsh-theme" = {
        source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/oh-my-zsh-custom/raw/main/amuse-custom.zsh-theme";
          hash = "sha256-TuR1qNxEUmP2ov0ElHXGhZDiu/BbQgbjMpvINQE8J08=";
        };
      };

      "imgs/system/wallpaper.jpg" = {
        source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/imgs/raw/main/wallpaper.jpg";
          hash = "sha256-6Wjn186dYxq1tpAqyXu1EhfkXiAgoSeuKntfyFV3Rro=";
        };
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        s               = "/etc/joshvanl/window-manager/start.sh";
        editn           = "vim /keep/etc/nixos/configuration.nix";
        update          = "sudo nixos-rebuild switch --upgrade-all -I nixos-config=/keep/etc/nixos/configuration.nix && rm -f $HOME/.zsh_history && ln -s /persist/home/.zsh_history $HOME/.zsh_history && source $HOME/.zshrc";
        update-channel  = "sudo nix-channel --update";
        garbage-collect = "sudo nix-collect-garbage -d";
        programs        = "vim /keep/etc/nixos/modules/common/programs.nix";
        links           = "vim /keep/etc/nixos/modules/common/links.nix";
        hist            = "rm -f $HOME/.zsh_history && ln -s /persist/home/.zsh_history $HOME/.zsh_history";
        screen          = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Wayfire && systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr && systemctl --user start wireplumber";
        sshbye          = "gpg-connect-agent updatestartuptty /bye";
        shot            = "grim -g \"$(slurp)\" - | wl-copy -t image/png";

        kc = "kubectl";
        kg = "kubectl get";

        gog  = "GO111MODULE=off go get -v";
        gogg = "go get -v";
        got  = "go test -v";
        goi  = "go mod tidy -v";
        gob  = "go build -v";
        gon  = "go install -v";
        gov  = "go vet -v";

        l    = "ls -lah --group-directories-first";
        ci   = "xclip -selection clipboard -i";
        co   = "xclip -o";
        tmp  = "cd $(mktemp -d)";
        gcil = "gcloud compute instances list";
        wkc  = "watch -n 0.2 kubectl";
        kcw  = "watch -n 0.2 kubectl";
        kwc  = "watch -n 0.2 kubectl";
        kccm = "kubectl cert-manager";
        cdc  = "cd $HOME/go/src/github.com/cert-manager/cert-manager";
        cdp  = "cd $HOME/go/src/github.com/cert-manager/approver-policy";
        cdj  = "cd $HOME/go/src/github.com/jetstack/jetbot";
        cdo  = "cd $HOME/go/src/github.com/jetstack/oob-issuer";
        cdt  = "cd $HOME/go/src/github.com/cert-manager/istio-csr";
        cdi  = "cd $HOME/go/src/github.com/cert-manager/csi-lib";
        cdm  = "cd $HOME/go/src/github.com/cert-manager/istio-csi";
        cda  = "cd $HOME/go/src/github.com/cert-manager/csi-driver";
        cdd  = "cd $HOME/go/src/github.com/cert-manager/trust";
        cdw  = "cd $HOME/go/src/github.com/cert-manager/website";
        cdds = "cd $HOME/go/src/github.com/cert-manager/csi-driver-spiffe";
        cdr  = "cd $HOME/go/src/github.com/jetstack/approver-policy-rego";
        cdu  = "cd $HOME/go/src/github.com/jetstack/spiffe-connector-vault";
        cde  = "cd $HOME/go/src/github.com/jetstack/approver-policy-enterprise";
        cds  = "cd $HOME/go/src/github.com/jetstack/js-trust";
        cdn  = "cd /keep/etc/nixos";
      };
      history = {
        size = 100000;
      };
      initExtra = ''
      rm -f $HOME/.zsh_history && ln -s /persist/home/.zsh_history $HOME/.zsh_history
      rm -f $HOME/.viminfo     && ln -s /persist/home/.viminfo     $HOME/.viminfo
      if [ -n "$\{commands[fzf-share]\}" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi
      eval "$(direnv hook zsh)"
      '';
      oh-my-zsh = {
        enable = true;
        theme = "amuse-custom";
        custom = "$HOME/.config/oh-my-zsh";
        plugins = [ "git" ];
      };
      sessionVariables = {
        VISUAL  = "vim";
        EDITOR  = "vim";
        BROWSER = "firefox";
        GOPATH  = "$HOME/go";
        GOBIN   = "$HOME/go/bin";
        GOPROXY = "https://proxy.golang.org";
      };
    };
  };
}
