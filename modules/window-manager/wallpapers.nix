{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.me.window-manager.wallpapers;
  wmCfg = config.me.window-manager;

  envAttrs = {
    WP_QUEUE = cfg.queueDir;
    WP_LIBRARY = cfg.libraryDir;
    WP_BLACKLIST = cfg.blacklistPath;
    WP_QUERY = cfg.query;
    WP_CATEGORIES = cfg.categories;
    WP_PURITY = cfg.purity;
    WP_ATLEAST = cfg.atLeast;
    WP_SORTING = cfg.sorting;
    WP_TOPRANGE = cfg.topRange;
    WP_LIBRARY_MAX = toString cfg.libraryMax;
    WP_FETCH_COUNT = toString cfg.fetchCount;
  };

  envList = mapAttrsToList (k: v: "${k}=${v}") envAttrs;

in {
  options.me.window-manager.wallpapers = {
    enable = mkOption {
      type = types.bool;
      default = wmCfg.enable;
      description = "Enable the wp wallpaper queue/library manager.";
    };

    queueDir = mkOption {
      type = types.str;
      default = "/keep/etc/wallpapers/queue";
      description = ''
        Candidate queue. Ephemeral by nature (redownloadable), so lives on
        /keep rather than /persist.
      '';
    };

    libraryDir = mkOption {
      type = types.str;
      default = "/keep/etc/wallpapers/library";
      description = ''
        Kept wallpapers used by the feh service. Ephemeral by nature
        (redownloadable), so lives on /keep rather than /persist.
      '';
    };

    blacklistPath = mkOption {
      type = types.str;
      default = "/persist/etc/wallpapers/blacklist";
      description = ''
        File of sha256 hashes that wp will never re-add. Represents
        accumulated taste, so lives on /persist for backup.
      '';
    };

    query = mkOption {
      type = types.str;
      default = "landscape";
      description = "Wallhaven search query.";
    };

    categories = mkOption {
      type = types.str;
      default = "100";
      description = "Wallhaven categories bitmask: General/Anime/People.";
    };

    purity = mkOption {
      type = types.str;
      default = "100";
      description = "Wallhaven purity bitmask: SFW/Sketchy/NSFW.";
    };

    atLeast = mkOption {
      type = types.str;
      default = "2560x1440";
      description = "Minimum image resolution.";
    };

    sorting = mkOption {
      type = types.str;
      default = "toplist";
      description = "Wallhaven sort order.";
    };

    topRange = mkOption {
      type = types.str;
      default = "1M";
      description = "Time range for toplist sort: 1d, 3d, 1w, 1M, 3M, 6M, 1y.";
    };

    libraryMax = mkOption {
      type = types.int;
      default = 200;
      description = "Cap on library size before oldest is pruned.";
    };

    fetchCount = mkOption {
      type = types.int;
      default = 12;
      description = "Number of candidates pulled per fetch.";
    };

    fetchInterval = mkOption {
      type = types.str;
      default = "weekly";
      description = "systemd OnCalendar expression for the fetch timer.";
    };
  };

  config = mkIf (wmCfg.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d ${cfg.queueDir}                       0755 ${config.me.username} users -"
      "d ${cfg.libraryDir}                     0755 ${config.me.username} users -"
      "d ${dirOf cfg.blacklistPath}            0755 ${config.me.username} users -"
      "f ${cfg.blacklistPath}                  0644 ${config.me.username} users -"
    ];

    home-manager.users.${config.me.username} = {
      home.packages = [ pkgs.wp ];
      home.sessionVariables = envAttrs;

      systemd.user.services.wp-fetch = {
        Unit.Description = "fetch new wallpaper candidates into queue";
        Service = {
          Type = "oneshot";
          Environment = envList;
          ExecStart = "${pkgs.wp}/bin/wp fetch";
        };
      };

      systemd.user.timers.wp-fetch = {
        Unit.Description = "periodic wallpaper fetch";
        Timer = {
          OnCalendar = cfg.fetchInterval;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
