{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.data.cache.container;

  storagePath = "/run/docker-registry";

  regpairOption = mkOptionType {
    name = "regpair";
    description = "registry pair option";
    # Must be a single registry domain string, or a registry attribute pair
    # with name and upstream attributes.
    check = value: (isString value) || ((isAttrs value) && (compareLists compare (attrNames value) ["name" "upstream"] == 0));
  };

  regName = regpair: if (isString regpair) then regpair else regpair.name;
  regUp = regpair: if (isString regpair) then regpair else regpair.upstream;

  registryConfig = i: {
    version =  "0.1";
    log.fields.service = "registry";
    storage = {
      cache.blobdescriptor = "inmemory";
      delete.enabled = false;
      filesystem.rootdirectory = "${storagePath}/${regName (elemAt cfg.registries i)}";
    };
    http = {
      addr = "127.0.0.1:${toString (6000 + i)}";
      headers.X-Content-Type-Options = ["nosniff"];
    };
    health.storagedriver = {
      enabled = true;
      interval = "10s";
      threshold = 3;
    };
    proxy = {
      remoteurl = "https://${regUp (elemAt cfg.registries i)}";
    };
  };

  configFile = i: pkgs.writeText "docker-registry-config.yml" (builtins.toJSON (registryConfig i));

in {
  options.me.data.cache.container = {
    enable = mkEnableOption "container";
    domain = mkOption {
      type = types.str;
      description = ''
        Domain name to serve the container cache on.
      '';
    };
    registries = mkOption {
      type = types.listOf regpairOption;
      default = [];
      description = ''
        List of registry domains to pull throuch proxy cache. Each element is
        either the domain of the registry as a string, or an attribute pair for
        registries that have a vanity domain.
      '';
      example = [
        "ghcr.io"
        {name = "docker.io"; upstream = "registry-1.docker.io";}
      ];
    };
    cacheDir = mkOption {
      type = types.str;
      default = "/keep/run/container/cache";
    };
    garbageCollectDates = mkOption {
      type = types.str;
      default = "semianually";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {assertion = (length cfg.registries > 0); message = "At least one registry must be configured.";}
      {assertion = (stringLength cfg.domain > 0); message = "Must declare container registry server domain";}
    ];

    users = {
      users.docker-registry = {
        group = "docker-registry";
        isSystemUser = true;
      };
      groups.docker-registry = {};
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.cacheDir} 0755 docker-registry docker-registry -"
      "d ${storagePath} 0755 docker-registry docker-registry -"
    ];

    fileSystems = {
      "${storagePath}" = { options = [ "bind" ]; device = "${cfg.cacheDir}"; };
    };

    systemd.services = listToAttrs (flatten (imap0 (i: registry: [
      {
        name = "docker-registry-${regName registry}";
        value = {
          description = "Docker Container Registry ${regName registry}";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.docker-distribution}/bin/registry serve ${configFile i}
          '';

          serviceConfig = {
            User = "docker-registry";
            WorkingDirectory = storagePath;
            Restart = "on-failure";
          };
        };
      }
      {
        name = "docker-registry-garbage-collec-${regName registry}";
        value = {
          description = "Run Garbage Collection for docker registry ${regName registry}";
          restartIfChanged = false;
          unitConfig.X-StopOnRemoval = false;
          serviceConfig.Type = "oneshot";
          script = ''
            ${pkgs.docker-distribution}/bin/registry garbage-collect ${configFile i}
            /run/current-system/systemd/bin/systemctl restart docker-registry.service
          '';
          startAt = cfg.garbageCollectDates;
        };
      }
    ]) cfg.registries));

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${cfg.domain}" = {
          # Block POST/PUT/DELETE. Don't use this proxy for pushing.
          extraConfig = ''
            if ($request_method = POST) {
                return 405;
            }
            if ($request_method = PUT) {
                return 405;
            }
            if ($request_method = DELETE) {
                return 405;
            }
          '';
          locations = listToAttrs (imap0 (i: registry: {
            name = "/v2/${regName registry}";
            value = {
              extraConfig = ''
                rewrite ^/${regName registry}/(.*)$ /$1 break;
                rewrite ^/v2/${regName registry}/(.*)$ /v2/$1 break;
                proxy_pass http://localhost:${toString (add 6000 i)};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };
          }) cfg.registries) // {
            "/v2" = {
              extraConfig = ''
                return 200 "true";
              '';
            };
          };
        };
      };
    };
  };
}
