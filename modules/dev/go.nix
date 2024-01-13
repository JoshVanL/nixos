{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.go;

in {
  options.me.dev.go = {
    enable = mkEnableOption "dev.go";
    extraProxies = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra GOPROXY values to use";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /keep/home/go 0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/go - - - - /keep/home/go"
    ];

    home-manager.users.${config.me.username} = {
      systemd.user.services.gopls = {
        Unit.Description = "gopls daemon";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkgs.gopls}/bin/gopls -listen=unix;%t/gopls";
          Environment = [ "PATH=${pkgs.go}/bin" ];
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
          go-mockery
          gofumpt
          gotools
          gcc
        ];

        sessionVariables = {
          GOPRIVATE = "github.com/diagridio,github.com/joshvanl";
          GOPATH  = "$HOME/go";
          GOBIN   = "$HOME/go/bin";
          GOPROXY = concatStrings (intersperse
            "," (cfg.extraProxies ++ [ "https://proxy.golang.org" ]));
        };
      };

      programs.git.extraConfig.url."ssh://git@github.com/diagridio".insteadOf = "https://github.com/diagridio";

      programs.neovim = {
        plugins = with pkgs.vimPlugins; [
          vim-go
        ];
        extraConfig = ''
          :autocmd FileType go map <C-n> :cn<CR>
          :autocmd FileType go map <C-p> :cp<CR>
          :autocmd FileType go cmap gg GoBuild <CR>
          :autocmd FileType go cmap tt GoTest -race -v <CR>
          :autocmd FileType go nmap gi :GoIfErr <CR>
          :autocmd FileType go nmap <C-i> :GoImports <CR>

          let g:go_highlight_types = 1
          let g:go_highlight_fields = 1
          let g:go_highlight_functions = 1
          let g:go_highlight_function_calls = 1
          let g:go_highlight_extra_types = 1
          let g:go_gopls_options = ['-remote=unix;/run/user/1000/gopls']
          let g:go_build_tags = 'e2e perf conftests unit integration integration_test certtests allcomponents'
        '';
      };

      programs.zsh.shellAliases = {
        gog = "GO111MODULE=off go get -v";
        gogg = "go get -v";
        got = "go test --race -v";
        goi = "go mod tidy -v";
        gob = "go build -v";
        gon = "go install -v";
        gov = "go vet -v";
        gotu = "got -tags unit";
        goti = "got -tags integration";

        cdc = "cd $HOME/go/src/github.com/cert-manager/cert-manager";
        cdp = "cd $HOME/go/src/github.com/cert-manager/approver-policy";
        cdj = "cd $HOME/go/src/github.com/jetstack/jetbot";
        cdo = "cd $HOME/go/src/github.com/jetstack/isolated-issuer";
        cdt = "cd $HOME/go/src/github.com/cert-manager/istio-csr";
        cdi = "cd $HOME/go/src/github.com/cert-manager/csi-lib";
        cdm = "cd $HOME/go/src/github.com/cert-manager/istio-csi";
        cda = "cd $HOME/go/src/github.com/cert-manager/csi-driver";
        cdd = "cd $HOME/go/src/github.com/dapr/dapr";
        cddc = "cd $HOME/go/src/github.com/dapr/components-contrib";
        cdw = "cd $HOME/go/src/github.com/cert-manager/website";
        cdds = "cd $HOME/go/src/github.com/cert-manager/csi-driver-spiffe";
        cdr = "cd $HOME/go/src/github.com/jetstack/approver-policy-rego";
        cdu = "cd $HOME/go/src/github.com/jetstack/spiffe-connector-vault";
        cde = "cd $HOME/go/src/github.com/jetstack/approver-policy-enterprise";
        cds = "cd $HOME/go/src/github.com/jetstack/js-trust";
        cdy = "cd /$HOME/go/src/github.com/joshvanl/yazbu";
      };
    };
  };
}
