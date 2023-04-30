{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.machinecache;

  builderSH = pkgs.writeShellApplication {
    name = "build_machines.sh";
    runtimeInputs = with pkgs; [ nix git ];
    text = ''
      TMPDIR=$(mktemp -d)

      trap 'rm -rf -- "$TMPDIR"' EXIT

      git clone ${cfg.machineRepo} "''${TMPDIR}/."

      ARCHS=()
      find "''${TMPDIR}"/machines/ -type d -exec sh -c '
        mapfile -t ARCHS < <(basename -- "$1")
      ' sh {} \;

      MACHINES=()
      for arch in "''${ARCHS[@]}"
      do
        find "''${TMPDIR}"/machines/"''${arch}" -type f -exec sh -c '
          mapfile -t MACHINES < <(basename -- "$1" | cut -f 1 -d ".")
        ' sh {} \;
      done

      echo ">>Found machines: \[''${MACHINES[*]}\]"

      for machine in "''${MACHINES[@]}"
      do
        echo ">>Building machine: \[''${machine}\]"
        nix build -L "''${TMPDIR}"#nixosConfigurations."''${machine}".config.system.build.toplevel
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
          };
        };
      };
    };

    systemd = {
      timers."machine_builder.timer" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar=cfg.timerOnCalendar;
          Unit = "machine_builder.service";
        };
      };

      services."machine_builder" = {
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
