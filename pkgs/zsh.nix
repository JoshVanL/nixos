{ pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
in {
  imports = [
    "${home-manager}/nixos"
  ];

  home-manager.users.josh = { pkgs, ... }: {
    home.file = {
      ".config/oh-my-zsh/themes/kubectl.zsh" = {
        source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/oh-my-zsh-custom/raw/main/kubectl.zsh";
          hash = "sha256-AMevJrEFeYGOEKCCJjvDbnRLdvguuhfxhqW+k/TnAlU=";
        };
      };
      ".config/oh-my-zsh/themes/amuse-custom.zsh-theme" = {
        source = pkgs.fetchurl {
          url = "https://github.com/JoshVanL/oh-my-zsh-custom/raw/main/amuse-custom.zsh-theme";
          hash = "sha256-8dYPqTVcC68To2mZ5XxlZBe8K5UbsAi62aVr9YzsBnk=";
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
      shellAliases = {
        s = "dwl -s \"swaybg -i $HOME/imgs/system/wallpaper.jpg <&-\"";
        editn = "vim /persist/etc/nixos/configuration.nix";
        update = "sudo nixos-rebuild switch";
        update-channel = "sudo nix-channel --update";
        garbage-collect = "sudo nix-collect-garbage -d";
        kc = "kubectl";
        kg = "kubectl get";
        l = "ls -lah --group-directories-first";
        gog = "GO111MODULE=off go get -v";
        gogg = "go get -v";
        got = "go test -v";
        goi = "go mod tidy -v";
        gob = "go build -v";
        gon = "go install -v";
        gov = "go vet -v";

        ci = "xclip -selection clipboard -i";
        co = "xclip -o";
        tmp = "cd $(mktemp -d)";
        x = "startx &> ~/.cache/Xoutput";
        gcil = "gcloud compute instances list";
        wkc = "watch -n 0.2 kubectl";
        kcw = "watch -n 0.2 kubectl";
        kwc = "watch -n 0.2 kubectl";
        kccm = "kubectl cert-manager";
        cdc = "cd $HOME/go/src/github.com/cert-manager/cert-manager";
        cdp = "cd $HOME/go/src/github.com/cert-manager/approver-policy";
        cdj = "cd $HOME/go/src/github.com/jetstack/jetbot";
        cdo = "cd $HOME/go/src/github.com/jetstack/oob-issuer";
        cdt = "cd $HOME/go/src/github.com/cert-manager/istio-csr";
        cdi = "cd $HOME/go/src/github.com/cert-manager/csi-lib";
        cdm = "cd $HOME/go/src/github.com/cert-manager/istio-csi";
        cda = "cd $HOME/go/src/github.com/cert-manager/csi-driver";
        cdd = "cd $HOME/go/src/github.com/cert-manager/trust";
        cdw = "cd $HOME/go/src/github.com/cert-manager/website";
        cdds = "cd $HOME/go/src/github.com/cert-manager/csi-driver-spiffe";
        cdr = "cd $HOME/go/src/github.com/jetstack/approver-policy-rego";
        cdu = "cd $HOME/go/src/github.com/jetstack/spiffe-connector-vault";
        cde = "cd $HOME/go/src/github.com/jetstack/approver-policy-enterprise";
        cds = "cd $HOME/go/src/github.com/jetstack/js-trust";
      };
      history = {
        size = 100000;
      };
      oh-my-zsh = {
        enable = true;
        theme = "amuse-custom";
        custom = "$HOME/.config/oh-my-zsh";
        plugins = [ "git" ];
      };
      sessionVariables = {
        VISUAL = "vim";
        EDITOR = "vim";
        BROWSER = "firefox";
        GOPATH = "$HOME/go";
        GOBIN = "$HOME/go/bin";
        GOPROXY = "https://proxy.golang.org";
      };
    };
  };
}
