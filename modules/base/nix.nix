{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.nix;

  updateSH = pkgs.writeShellApplication {
    name = "update";
    runtimeInputs = with pkgs; [
      nixos-rebuild
      specialisation
    ];
    text = ''
      specArg=""
      CURRENT_SPEC="$(specialisation -q)"
      if [ "$CURRENT_SPEC" != "main" ]; then
        specArg="--specialisation $CURRENT_SPEC"
      fi
      cmd="sudo nixos-rebuild switch -L --flake '/keep/etc/nixos/.#' $specArg"
      eval "$cmd"
    '';
  };

in {
  options.me.base.nix = {
    extraSubstituters = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        A list of extra Nix binary caches to use.
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

    specialisation = {
      postCommands = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          A list of commands to run after switching to a specialisation.
        '';
      };
    };
  };

  config = {
    nix = {
      settings = {
        allowed-users = [ "root" "${config.me.username}"];
        auto-optimise-store = false;
        substituters = [ "https://cache.nixos.org" ] ++ cfg.extraSubstituters;
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
    system.stateVersion = "23.11";

    environment.etc."nixos".source = "/keep/etc/nixos";

    nixpkgs.config.allowUnsupportedSystem = true;

    home-manager.users.${config.me.username} = {
      home.packages = with pkgs; [
        updateSH
        gimmi
        specialisation
      ];

      xdg.configFile."specialisation/post-command.sh" = let
        postCommand = pkgs.writeShellApplication {
            name = "specialisation-post-command";
            text = ''
              ${concatStringsSep "\n" cfg.specialisation.postCommands}
            '';
          };
      in {
        enable = cfg.specialisation.postCommands != [];
        source = "${postCommand}/bin/specialisation-post-command";
        executable = true;
      };

      programs.zsh.shellAliases = mkIf config.me.shell.zsh.enable {
        flake = "nix flake";
        garbage-collect = "sudo nix-collect-garbage -d";
      };
    };
  };
}
