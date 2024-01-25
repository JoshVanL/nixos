{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.nix;

  homeDir = config.home-manager.users.${config.me.username}.home.homeDirectory;

  nixconfSH = pkgs.writeShellApplication {
    name = "nix-conf";
    text = ''
      TARGETDIR="${homeDir}/.config/${config.me.username}"
      TARGET="$TARGETDIR/nix.conf"
      GITHUB_TOKEN="/persist/etc/github/token"
      echo ">> Writing $TARGET"
      rm -rf "$TARGETDIR" && mkdir -p "$TARGETDIR"
      if [ -f "$GITHUB_TOKEN" ]; then
        echo ">> Found github token in $GITHUB_TOKEN"
        echo "access-tokens = github.com=$(cat $GITHUB_TOKEN)"
        echo "access-tokens = github.com=$(cat $GITHUB_TOKEN)" > "$TARGET"
      else
        echo ">> Did not find github token in $GITHUB_TOKEN"
        truncate -s 0 "$TARGET"
      fi
      echo ">> Wrote $TARGET"
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

    home-manager.users.${config.me.username} = let
      hmlib = config.home-manager.users.${config.me.username}.lib;
    in {
      home.packages = with pkgs; [
        update
        gimmi
        specialisation
      ];

      home.activation."nix-conf" = hmlib.dag.entryAfter
        ["writeBoundary"] "${nixconfSH}/bin/nix-conf";

      xdg.configFile = {
        "nix/nix.conf".source = hmlib.file.mkOutOfStoreSymlink
          "${homeDir}/.config/${config.me.username}/nix.conf";
        "specialisation/post-command.sh" = let
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
      };

      programs.zsh.shellGlobalAliases = mkIf config.me.shell.zsh.enable {
        flake = "nix flake";
        garbage-collect = "sudo nix-collect-garbage -d";
      };
    };
  };
}
