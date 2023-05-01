{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.machinecache;

  builderSH = pkgs.writeShellApplication {
    name = "build_machines.sh";
    runtimeInputs = with pkgs; [ nix git bash ];
    text = ''
      TMPDIR=$(mktemp -d)
      cd "$TMPDIR"
      trap 'cd - && rm -rf -- "$TMPDIR"' EXIT

      git clone https://github.com/joshvanl/nixos "''${TMPDIR}/."

      while IFS= read -r -d ''+"'' "+''arch
      do
        if [[ "''${arch}" == "''${TMPDIR}/machines/" ]]; then
          continue
        fi
        ARCHS+=("$(basename -- "$arch")")
      done <   <(find "''${TMPDIR}"/machines/ -type d -print0)

      echo ">>Found architectures: [''${ARCHS[*]}]"

      MACHINES=()
      for arch in "''${ARCHS[@]}"
      do
        while IFS= read -r -d ''+"'' "+''machine
        do
          MACHINES+=("$(basename -- "$machine" | cut -f 1 -d ".")")
        done <   <(find "''${TMPDIR}"/machines/"''${arch}" -type f -print0)
      done

      echo ">>Found machines: [''${MACHINES[*]}]"

      for machine in "''${MACHINES[@]}"
      do
        echo ">>Building machine: [''${machine}]"
        nix build -L --no-eval-cache --keep-going "''${TMPDIR}"#nixosConfigurations."''${machine}".config.system.build.toplevel
      done

      echo ">>All machines built!"
    '';
  };

in {
  options.me.data.machinecache = {
    enable = mkEnableOption "machinecache";
    domain = mkOption {
      type = types.str;
    };
    priority = mkOption {
      type = types.str;
      default = "38";
      description = ''
        Set Priority of Nix cache. Remeber that a lower number gives higher priorty!
        For reference, cache.nixos.org has a priority of 40.
      '';
    };
    secretKeyFile = mkOption {
      type = types.str;
    };
    machineRepo = mkOption {
      type = types.str;
    };
    timerOnCalendar = mkOption {
      type = types.str;
      default = "*-*-* 4:00:00";
    };
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [ "nix-serve"];
    services = {
      nix-serve = {
        enable = true;
        secretKeyFile = cfg.secretKeyFile;
      };

      nginx = {
        enable = true;
        virtualHosts = {
          "${cfg.domain}" = {
            forceSSL = true;
            enableACME = true;
            acmeRoot = null;
            locations."/".extraConfig = ''
              proxy_pass http://localhost:${toString config.services.nix-serve.port};
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
            locations."/nix-cache-info".extraConfig = ''
              return 200 "StoreDir: /nix/store\nWantMassQuery: 1\nPriority: ${cfg.priority}\n";
            '';
          };
        };
      };
    };

    systemd = {
      timers."machine-builder" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar=cfg.timerOnCalendar;
          Unit = "machine-builder.service";
        };
      };

      services."machine-builder" = {
        enable = true;
        description = "NixOS machine builder";
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          WorkingDirectory = "/tmp";
          ExecStart = "${builderSH}/bin/build_machines.sh";
          Restart = "no";
        };
      };
    };
  };
}
