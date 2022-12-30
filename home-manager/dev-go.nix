{ config, lib, pkgs, ... }:

{
  # install core golang dev packages
  home.packages = with pkgs; [
    go-junit-report
    golangci-lint
    gopls
    go_1_19
  ];

  programs.neovim = {
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
    '';
  };

  systemd.user.services.gopls = {
    Unit = {
      Description = "Run the go language server as user daemon, so we can limit its memory and CPU usage";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [ "PATH=/run/wrappers/bin:/home/${config.home.username}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin" ];
      ExecStartPre = "/run/current-system/sw/bin/rm -f %t/gopls-daemon-socket";
      ExecStart = "${pkgs.gopls}/bin/gopls -listen=\"unix;%t/gopls-daemon-socket\" -logfile=auto -debug=:0";
      Restart = "always";
      MemoryLimit = "6G";
      IOSchedulingClass = "3";
      OOMScoreAdjust = "500";
      CPUSchedulingPolicy = "idle";
    };

    Install = {
      WantedBy = [ "basic.target" ];
    };
  };
}
