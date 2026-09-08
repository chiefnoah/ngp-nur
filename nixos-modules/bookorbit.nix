{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.bookorbit;
  package = pkgs.callPackage ../pkgs/bookorbit { };
  credentials = {
    jwt-secret = cfg.secrets.jwtSecretFile;
    setup-bootstrap-token = cfg.secrets.setupBootstrapTokenFile;
  }
  // lib.optionalAttrs (cfg.secrets.emailEncryptionKeyFile != null) {
    email-encryption-key = cfg.secrets.emailEncryptionKeyFile;
  }
  // lib.optionalAttrs (cfg.secrets.migrationEncryptionKeyFile != null) {
    migration-encryption-key = cfg.secrets.migrationEncryptionKeyFile;
  }
  // lib.optionalAttrs (cfg.secrets.bookRequestEncryptionKeyFile != null) {
    book-request-encryption-key = cfg.secrets.bookRequestEncryptionKeyFile;
  }
  // lib.optionalAttrs (cfg.database.urlFile != null) {
    database-url = cfg.database.urlFile;
  };
  loadCredentials = lib.mapAttrsToList (name: path: "${name}:${path}") credentials;
  readCredential = name: ''"$(<"$CREDENTIALS_DIRECTORY/${name}")"'';
  startScript = pkgs.writeShellApplication {
    name = "bookorbit-start";
    text = ''
      JWT_SECRET=${readCredential "jwt-secret"}
      SETUP_BOOTSTRAP_TOKEN=${readCredential "setup-bootstrap-token"}
      export JWT_SECRET SETUP_BOOTSTRAP_TOKEN
      ${lib.optionalString (cfg.secrets.emailEncryptionKeyFile != null) ''
        EMAIL_ENCRYPTION_KEY=${readCredential "email-encryption-key"}
        export EMAIL_ENCRYPTION_KEY
      ''}
      ${lib.optionalString (cfg.secrets.migrationEncryptionKeyFile != null) ''
        MIGRATION_ENCRYPTION_KEY=${readCredential "migration-encryption-key"}
        export MIGRATION_ENCRYPTION_KEY
      ''}
      ${lib.optionalString (cfg.secrets.bookRequestEncryptionKeyFile != null) ''
        BOOK_REQUEST_ENCRYPTION_KEY=${readCredential "book-request-encryption-key"}
        export BOOK_REQUEST_ENCRYPTION_KEY
      ''}
      ${lib.optionalString (cfg.database.urlFile != null) ''
        DATABASE_URL=${readCredential "database-url"}
        export DATABASE_URL
      ''}

      ${lib.getExe' cfg.package "bookorbit-migrate"}
      exec ${lib.getExe cfg.package}
    '';
  };
  prepareDatabase = pkgs.writeShellApplication {
    name = "bookorbit-database-prepare";
    runtimeInputs = [ config.services.postgresql.finalPackage ];
    text = ''
      psql --dbname bookorbit --set ON_ERROR_STOP=1 <<'SQL'
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE EXTENSION IF NOT EXISTS vector;
      SQL
    '';
  };
in
{
  options.services.bookorbit = {
    enable = lib.mkEnableOption "BookOrbit";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = "the BookOrbit package provided by ngp-nur";
      description = "BookOrbit package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "bookorbit";
      description = "User account that runs BookOrbit.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "bookorbit";
      description = "Group that runs BookOrbit.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bookorbit";
      description = "Directory for covers, uploads, and application data.";
    };

    libraryBrowseRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bookorbit/books";
      description = "Top directory shown in the library folder picker.";
    };

    bookDockPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional directory for automatic book imports.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "TCP port on which BookOrbit listens.";
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:${toString cfg.port}";
      defaultText = "http://localhost:<port>";
      description = "External URL used in emails and device endpoints.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the BookOrbit port in the firewall.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        LOG_LEVEL = "debug";
        TRUST_PROXY = "127.0.0.1";
      };
      description = "Non-secret environment variables for BookOrbit.";
    };

    secrets = {
      jwtSecretFile = lib.mkOption {
        type = lib.types.str;
        description = "File that contains the JWT signing secret.";
      };

      setupBootstrapTokenFile = lib.mkOption {
        type = lib.types.str;
        description = "File that contains the initial setup token.";
      };

      emailEncryptionKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File that contains the SMTP credential encryption key.";
      };

      migrationEncryptionKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File that contains the migration credential encryption key.";
      };

      bookRequestEncryptionKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File that contains the book-request credential encryption key.";
      };
    };

    database = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create and configure a local PostgreSQL database.";
      };

      urlFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File that contains an external PostgreSQL URL.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.database.createLocally != (cfg.database.urlFile != null);
        message = "Set exactly one of services.bookorbit.database.createLocally and database.urlFile";
      }
    ];

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      extensions = ps: [ ps.pgvector ];
      ensureDatabases = [ "bookorbit" ];
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.bookorbit = {
      description = "BookOrbit library and reading platform";
      documentation = [ "https://bookorbit.app/installation" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
      ]
      ++ lib.optional cfg.database.createLocally "bookorbit-database.service";
      requires = lib.optional cfg.database.createLocally "bookorbit-database.service";
      environment = {
        APP_DATA_PATH = cfg.dataDir;
        APP_URL = cfg.appUrl;
        APP_VERSION = cfg.package.version;
        CLIENT_URL = cfg.appUrl;
        DATABASE_URL = lib.optionalString cfg.database.createLocally "postgresql://${cfg.user}@/bookorbit?host=/run/postgresql";
        FFPROBE_PATH = lib.getExe' pkgs.ffmpeg-headless "ffprobe";
        FFMPEG_PATH = lib.getExe pkgs.ffmpeg-headless;
        KOREADER_PLUGIN_PATH = "${cfg.package}/lib/bookorbit/koreader-plugin/bookorbit.koplugin";
        LIBRARY_BROWSE_ROOT = cfg.libraryBrowseRoot;
        NODE_ENV = "production";
        PORT = toString cfg.port;
      }
      // lib.optionalAttrs (cfg.package ? koboPython) {
        KOBO_CLOUDSCRAPER_PYTHON = "${cfg.package.koboPython}/bin/python";
      }
      // lib.optionalAttrs (cfg.bookDockPath != null) { BOOK_DOCK_PATH = cfg.bookDockPath; }
      // cfg.environment;
      serviceConfig = {
        ExecStart = lib.getExe startScript;
        User = cfg.user;
        Group = cfg.group;
        LoadCredential = loadCredentials;
        ReadWritePaths = [
          cfg.dataDir
          cfg.libraryBrowseRoot
        ]
        ++ lib.optional (cfg.bookDockPath != null) cfg.bookDockPath;
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
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
        RestrictRealtime = true;
      }
      // lib.optionalAttrs (cfg.dataDir == "/var/lib/bookorbit") {
        StateDirectory = "bookorbit";
      };
    };

    systemd.services.bookorbit-database = lib.mkIf cfg.database.createLocally {
      description = "Prepare the BookOrbit PostgreSQL database";
      after = [ "postgresql.target" ];
      requires = [ "postgresql.target" ];
      before = [ "bookorbit.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe prepareDatabase;
        User = "postgres";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.libraryBrowseRoot} 0750 ${cfg.user} ${cfg.group} -"
    ]
    ++ lib.optional (cfg.bookDockPath != null) "d ${cfg.bookDockPath} 0750 ${cfg.user} ${cfg.group} -";

    users.users.bookorbit = lib.mkIf (cfg.user == "bookorbit") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "BookOrbit service user";
    };
    users.groups.bookorbit = lib.mkIf (cfg.group == "bookorbit") { };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
