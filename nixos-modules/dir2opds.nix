{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dir2opds;
  dir2opdsPackage = pkgs.callPackage ../pkgs/dir2opds { };

  boolArg = name: value: "-${name}=${lib.boolToString value}";
  arguments = [
    "-host"
    cfg.listenAddress
    "-port"
    (toString cfg.port)
    "-dir"
    cfg.libraryDir
    (boolArg "debug" cfg.debug)
    (boolArg "hide-calibre-files" cfg.hideCalibreFiles)
    (boolArg "hide-dot-files" cfg.hideDotFiles)
    (boolArg "no-cache" cfg.noCache)
    (boolArg "enable-cache" cfg.enableCache)
    (boolArg "gzip" cfg.gzip)
    "-sort"
    cfg.sort
    (boolArg "show-covers" cfg.showCovers)
    (boolArg "search" cfg.search)
    (boolArg "extract-metadata" cfg.extractMetadata)
    (boolArg "enable-html" cfg.enableHTML)
    "-log-format"
    cfg.logFormat
    "-page-size"
    (toString cfg.pageSize)
    (boolArg "no-pagination" cfg.noPagination)
    (boolArg "koreader-mixed-feeds" cfg.koreaderMixedFeeds)
    (boolArg "pdf-covers" cfg.pdfCovers.enable)
  ]
  ++ lib.optionals (cfg.baseUrl != null) [
    "-url"
    cfg.baseUrl
  ]
  ++ lib.optionals (cfg.mimeMap != { }) [
    "-mime-map"
    (lib.concatStringsSep "," (
      lib.mapAttrsToList (extension: mime: "${extension}:${mime}") cfg.mimeMap
    ))
  ]
  ++ lib.optionals cfg.pdfCovers.enable [
    "-pdf-cover-cache-dir"
    cfg.pdfCovers.cacheDir
    "-pdf-cover-command"
    (lib.getExe' pkgs.poppler-utils "pdftoppm")
    "-pdf-cover-width"
    (toString cfg.pdfCovers.width)
    "-pdf-cover-quality"
    (toString cfg.pdfCovers.quality)
    "-pdf-cover-workers"
    (toString cfg.pdfCovers.workers)
    "-pdf-cover-timeout"
    cfg.pdfCovers.timeout
    "-pdf-cover-failure-ttl"
    cfg.pdfCovers.failureTtl
  ]
  ++ cfg.extraArgs;
in
{
  options.services.dir2opds = {
    enable = lib.mkEnableOption "dir2opds OPDS ebook server";

    package = lib.mkOption {
      type = lib.types.package;
      default = dir2opdsPackage;
      defaultText = "the dir2opds package provided by ngp-nur";
      description = "dir2opds package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "dir2opds";
      description = "User account that runs dir2opds.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "dir2opds";
      description = "Group that runs dir2opds.";
    };

    libraryDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/dir2opds/books";
      description = "Directory that contains the ebook library.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address on which dir2opds listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "TCP port on which dir2opds listens.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the dir2opds port in the firewall.";
    };

    debug = lib.mkEnableOption "request debug logs";
    gzip = lib.mkEnableOption "HTTP response compression";
    search = lib.mkEnableOption "filename search";
    enableHTML = lib.mkEnableOption "the HTML browser interface";
    noCache = lib.mkEnableOption "headers that disable client caching";
    enableCache = lib.mkEnableOption "ETag and Last-Modified headers";
    noPagination = lib.mkEnableOption "a single unpaginated feed";
    koreaderMixedFeeds = lib.mkEnableOption "mixed folder and book feeds for KOReader";

    hideCalibreFiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hide files that Calibre stores.";
    };

    hideDotFiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hide files whose names start with a dot.";
    };

    showCovers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use cover.jpg or folder.jpg as catalog covers.";
    };

    extractMetadata = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Extract metadata and covers from ebook files.";
    };

    sort = lib.mkOption {
      type = lib.types.enum [
        "name"
        "date"
        "size"
      ];
      default = "name";
      description = "Default catalog sort order.";
    };

    logFormat = lib.mkOption {
      type = lib.types.enum [
        "json"
        "text"
      ];
      default = "json";
      description = "Log output format.";
    };

    pageSize = lib.mkOption {
      type = lib.types.ints.between 0 200;
      default = 50;
      description = "Entries per page. Zero uses the application default.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://opds.example.com";
      description = "Public base URL used for absolute feed links.";
    };

    mimeMap = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        ".azw3" = "application/vnd.amazon.ebook";
        ".mobi" = "application/x-mobipocket-ebook";
      };
      description = "Additional file-extension to MIME-type mappings.";
    };

    pdfCovers = {
      enable = lib.mkEnableOption "PDF first-page covers";

      cacheDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/cache/dir2opds";
        description = "Directory for generated PDF covers.";
      };

      width = lib.mkOption {
        type = lib.types.ints.positive;
        default = 320;
        description = "PDF cover width in pixels.";
      };

      quality = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 80;
        description = "PDF cover JPEG quality.";
      };

      workers = lib.mkOption {
        type = lib.types.ints.positive;
        default = 2;
        description = "Maximum concurrent PDF cover renders.";
      };

      timeout = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Maximum duration of one PDF cover render.";
      };

      failureTtl = lib.mkOption {
        type = lib.types.str;
        default = "5m";
        description = "Duration that failed PDF renders remain cached.";
      };
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command-line arguments passed to dir2opds.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.noCache && cfg.enableCache);
        message = "services.dir2opds.noCache and enableCache cannot both be enabled";
      }
    ];

    systemd.services.dir2opds = {
      description = "dir2opds OPDS ebook server";
      documentation = [ "https://github.com/chiefnoah/dir2opds" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs arguments}";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0027";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      }
      // lib.optionalAttrs cfg.pdfCovers.enable {
        ReadWritePaths = [ cfg.pdfCovers.cacheDir ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.libraryDir} 0750 ${cfg.user} ${cfg.group} -"
    ]
    ++ lib.optional cfg.pdfCovers.enable "d ${cfg.pdfCovers.cacheDir} 0750 ${cfg.user} ${cfg.group} -";

    users.users.dir2opds = lib.mkIf (cfg.user == "dir2opds") {
      isSystemUser = true;
      group = cfg.group;
      description = "dir2opds service user";
    };
    users.groups.dir2opds = lib.mkIf (cfg.group == "dir2opds") { };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
