{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.shell.zsh;

  ffSH = pkgs.writeShellApplication {
    name = "ff";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      fn=''${1:-}
      dir=''${2:-.}
      find "$dir" -type f -iname "*.$fn"
    '';
  };

  grpSH = pkgs.writeShellApplication {
    name = "grp";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      e=''${1:-}
      dir=''${2:-.}
      grep --color=always -irn "$dir" -e "$e"
    '';
  };

in {
  options.me.shell.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    environment.pathsToLink = [ "/share/zsh/site-functions" ];
    programs.zsh.enable = true;

    # Point HISTFILE directly at the persisted path (see history.path below)
    # instead of symlinking ~/.zsh_history into /persist. zsh saves history with
    # HIST_SAVE_BY_COPY (on by default), writing a new file and rename()ing it
    # over $HISTFILE; a rename over a symlink would replace the symlink with a
    # regular file on the ephemeral root, silently breaking persistence. Writing
    # straight to /persist keeps the save atomic and the data persistent.
    systemd.tmpfiles.rules = [
      "d /persist/home                          0755 ${config.me.username} wheel - -"
      "L+ /home/${config.me.username}/.viminfo  - - - - /persist/home/.viminfo"
    ];

    home-manager.users.${config.me.username} = {
      home = {
        sessionPath = [ "$HOME/bin" ];

        file.".config/oh-my-zsh/themes/amuse-custom.zsh-theme".source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/joshvanl/oh-my-zsh-custom/main/amuse-custom.zsh-theme";
          hash = "sha256-Eerg4P7Ybjqbytr0nRVsvCT1+TEL447voKpbFwqANjE=";
        };

        packages = with pkgs; [
          bat
          ffSH
          grpSH
          fzf
          direnv
          ww
          tree
        ];
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        shellGlobalAliases = {
          l = "ls -lah --group-directories-first";
          tmp = "cd $(mktemp -d)";
          cdn = "cd /etc/nixos";
          watch = "watch -n 0.2 ";
          wa = "watch -n 0.2";
        };
        history = {
          size = 100000;
          path = "/persist/home/.zsh_history";
        };
        initContent = ''
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
      };
    };
  };
}
