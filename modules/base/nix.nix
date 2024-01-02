{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.base.nix;

  gimmiSH = pkgs.writeShellApplication {
    name = "gimmi";
    runtimeInputs = with pkgs; [ nix ];
    text = ''
      nix-shell -p "$@" --run "''${SHELL}"
    '';
  };

  currentSpecialisationSH = pkgs.writeShellApplication {
    name = "current-specialisation";
    text = ''
      CURRENT_SPEC="main"
      CURRENT_SPEC_DIR=$(readlink /run/current-system)
      for f in /nix/var/nix/profiles/system/specialisation/*; do
        if [ "$(readlink "$f")" = "$CURRENT_SPEC_DIR" ]; then
          CURRENT_SPEC=$(basename "$f")
          break
        fi
      done
      echo "$CURRENT_SPEC"
    '';
  };

  updateSH = pkgs.writeShellApplication {
    name = "update";
    runtimeInputs = with pkgs; [
      nixos-rebuild
      currentSpecialisationSH
    ];
    text = ''
      specArg=""
      CURRENT_SPEC="$(current-specialisation)"
      if [ "$CURRENT_SPEC" != "main" ]; then
        specArg="--specialisation $CURRENT_SPEC"
      fi
      cmd="sudo nixos-rebuild switch -L --flake '/keep/etc/nixos/.#' $specArg"
      eval "$cmd"
    '';
  };

  specialisationSH = pkgs.writeShellApplication {
    name = "specialisation";
    runtimeInputs = [ currentSpecialisationSH ];
    text = ''
      mapfile -t SPECIALISATIONS < <(ls /nix/var/nix/profiles/system/specialisation)
      SPECIALISATIONS=( "main" "''${SPECIALISATIONS[@]}" )

      containsSpec() {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
      }

      CURRENT_SPEC="$(current-specialisation)"
      if [ $# -ne 1 ]; then
          echo "Usage: specialisation <name>"
          echo "Names: ''${SPECIALISATIONS[*]}"
          echo "Current: ''${CURRENT_SPEC}"
          exit 1
      fi
      if ! containsSpec "$1" "''${SPECIALISATIONS[@]}"; then
        echo "Specialisation '$1' does not exist."
        exit 1
      fi
      if [ "$1" = "main" ]; then
          echo "Switching from '$CURRENT_SPEC' to 'main' configuration."
          sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      else
          echo "Switching from '$CURRENT_SPEC' to specialisation '$1'."
          sudo /nix/var/nix/profiles/system/specialisation/"$1"/bin/switch-to-configuration switch
      fi

      ${strings.concatLines cfg.specialisation.postCommands}
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
      home.packages = [
        updateSH
        gimmiSH
        specialisationSH
      ];

      programs.zsh.shellAliases = mkIf config.me.shell.zsh.enable {
        flake = "nix flake";
        garbage-collect = "sudo nix-collect-garbage -d";
      };
    };
  };
}
