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
    programs.zsh = {
      enable = true;
      shellAliases = {
        s = "dwl -s \"swaybg -i /persist/etc/nixos/dotfiles/wallpaper.jpg <&-\"";
        editn = "vim /persist/etc/nixos/configuration.nix";
        update = "sudo nixos-rebuild switch";
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
        custom = "/persist/etc/nixos/dotfiles/oh-my-zsh";
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
