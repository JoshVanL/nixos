{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.go;

in {
  options.me.dev.go = {
    enable = mkEnableOption "dev.go";
    proxy = mkOption {
      type = types.str;
      default = "https://proxy.golang.org";
      description = "The proxy to use for go modules";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /keep/home/go 0755 ${config.me.base.username} wheel - -"
      "L+ /home/${config.me.base.username}/go - - - - /keep/home/go"
    ];

    home-manager.users.${config.me.base.username} = {
      systemd.user.services.gopls = {
        Unit.Description = "gopls daemon";
        Install.WantedBy = [ "default.target" ];
        Service = {
          Environment = [ "PATH=/run/wrappers/bin:/home/${config.me.base.username}/.nix-profile/bin:/etc/profiles/per-user/${config.me.base.username}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin" ];
          ExecStart = "${pkgs.gopls}/bin/gopls -listen=unix;%t/gopls";
          ExecStopPost = "/run/current-system/sw/bin/rm -f %t/gopls";
          Restart = "always";
          RestartSec = 3;
          MemoryHigh = "10G";
          MemoryMax = "12G";
        };
      };
      home = {
        # install core golang dev packages
        packages = with pkgs; [
          go-junit-report
          golangci-lint
          gopls
          go
          gomarkdoc
          gotestsum
          mockery
          gofumpt
          gotools
          gcc
        ];

        sessionVariables = {
          GOPRIVATE = "github.com/diagridio";
          GOPATH  = "$HOME/go";
          GOBIN   = "$HOME/go/bin";
          GOPROXY = cfg.proxy;
        };
      };

      #programs.git.extraConfig.url."ssh://git@github.com:".insteadOf = "https://github.com/";

      programs.neovim = mkIf config.me.shell.neovim.enable {
        plugins = with pkgs.vimPlugins; [
          vim-go
        ];
        extraConfig = ''
          " Go build
          map <C-n> :cn<CR>
          map <C-p> :cp<CR>
          cmap gg GoBuild <CR>
          cmap tt GoTest <CR>
          nmap gi :GoIfErr <CR>
          nmap <C-i> :GoImports <CR>

          let g:go_highlight_types = 1
          let g:go_highlight_fields = 1
          let g:go_highlight_functions = 1
          let g:go_highlight_function_calls = 1
          let g:go_highlight_extra_types = 1
          let g:go_gopls_options = ['-remote=unix;/run/user/1000/gopls']
        '';
      };

      programs.zsh.shellAliases = {
        gog  = "GO111MODULE=off go get -v";
        gogg = "go get -v";
        got  = "go test --race -v";
        goi  = "go mod tidy -v";
        gob  = "go build -v";
        gon  = "go install -v";
        gov  = "go vet -v";

        cdc  = "cd $HOME/go/src/github.com/cert-manager/cert-manager";
        cdp  = "cd $HOME/go/src/github.com/cert-manager/approver-policy";
        cdj  = "cd $HOME/go/src/github.com/jetstack/jetbot";
        cdo  = "cd $HOME/go/src/github.com/jetstack/isolated-issuer";
        cdt  = "cd $HOME/go/src/github.com/cert-manager/istio-csr";
        cdi  = "cd $HOME/go/src/github.com/cert-manager/csi-lib";
        cdm  = "cd $HOME/go/src/github.com/cert-manager/istio-csi";
        cda  = "cd $HOME/go/src/github.com/cert-manager/csi-driver";
        cdd  = "cd $HOME/go/src/github.com/dapr/dapr";
        cddc = "cd $HOME/go/src/github.com/dapr/components-contrib";
        cdw  = "cd $HOME/go/src/github.com/cert-manager/website";
        cdds = "cd $HOME/go/src/github.com/cert-manager/csi-driver-spiffe";
        cdr  = "cd $HOME/go/src/github.com/jetstack/approver-policy-rego";
        cdu  = "cd $HOME/go/src/github.com/jetstack/spiffe-connector-vault";
        cde  = "cd $HOME/go/src/github.com/jetstack/approver-policy-enterprise";
        cds  = "cd $HOME/go/src/github.com/jetstack/js-trust";
        cdy  = "cd /$HOME/go/src/github.com/joshvanl/yazbu";
      };
    };
  };
}
