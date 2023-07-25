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

    systemd.tmpfiles.rules = [
      "L+ /home/${config.me.username}/.zsh_history - - - - /persist/home/.zsh_history"
    ];

    home-manager.users.${config.me.username} = {
      home = {
        file.".config/oh-my-zsh/themes/amuse-custom.zsh-theme".source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/joshvanl/oh-my-zsh-custom/main/amuse-custom.zsh-theme";
          hash = "sha256-aqd5rWF9BZmcGU8E9sKAKFR0cfh0Kn4i3ZRS/u4vyGw=";
        };

        packages = with pkgs; [
          ffSH
          grpSH
          fzf
          direnv
          ww
        ];
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        shellAliases = {
          l = "ls -lah --group-directories-first";
          tmp = "cd $(mktemp -d)";
          cdn = "cd /etc/nixos";
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
      };
    };
  };
}
