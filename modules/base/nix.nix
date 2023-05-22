{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.nix;

  updateSH = pkgs.writeShellApplication {
    name = "update";
    runtimeInputs = with pkgs; [ nixos-rebuild zsh ];
    text = ''
      sudo nixos-rebuild switch -L --flake '/keep/etc/nixos/.#'
      rm -f /home/${config.me.username}/.zsh_history
      ln -s /persist/home/.zsh_history /home/${config.me.username}/.zsh_history
      zsh -c "source /home/${config.me.username}/.zshrc"
    '';
  };

  gimmiSH = pkgs.writeShellApplication {
    name = "gimmi";
    runtimeInputs = with pkgs; [ nix zsh ];
    text = ''
      nix-shell -p "$@" --run "zsh"
    '';
  };

in {
  options.me.base.nix = {
    substituters = mkOption {
      type = types.listOf types.str;
      default = [ "https://cache.nixos.org" ];
      description = ''
        A list of Nix binary caches to use.
      '';
    };
    trusted-public-keys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of public keys of Nix binary caches to trust.
      '';
    };

    gc = {
      automatic = mkOption {
        type = types.bool;
        default = true;
      };
      dates = mkOption {
        type = types.str;
        default = "weekly";
      };
      options = mkOption {
        type = types.str;
        default = "--delete-older-than 7d";
      };
    };
  };

  config = {
    nix = {
      settings = {
        allowed-users = [ "root" "${config.me.username}"];
        auto-optimise-store = true;
        substituters = lib.mkBefore cfg.substituters;
        connect-timeout = 1;
        trusted-public-keys = lib.mkBefore cfg.trusted-public-keys;
      };


      gc = {
        automatic = cfg.gc.automatic;
        dates = cfg.gc.dates;
        options = cfg.gc.options;
      };

      settings.trusted-users = [ "root" "${config.me.username}" ];

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
    system.stateVersion = "22.11";

    environment.etc."nixos".source = "/keep/etc/nixos";

    nixpkgs.config.allowUnsupportedSystem = true;

    home-manager.users.${config.me.username} = {
      home.packages = [
        updateSH
        gimmiSH
      ];

      programs.zsh.shellAliases = mkIf config.me.shell.zsh.enable {
        flake = "nix flake";
        garbage-collect = "sudo nix-collect-garbage -d";
      };
    };
  };
}
