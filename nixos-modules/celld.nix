{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.celld;

  inherit (lib)
    escapeShellArgs
    getExe
    mkEnableOption
    mkForce
    mkIf
    mkOption
    optional
    types
    ;

  celldPackage = pkgs.callPackage ../pkgs/celld { };
  useGarage = cfg.s3 == null;
  bucket = if useGarage then "s3://${cfg.garage.bucket}" else cfg.s3.bucket;
  endpoint = if useGarage then "http://${cfg.garage.apiAddress}" else cfg.s3.endpoint;
  region = if useGarage then "garage" else cfg.s3.region;
  garageCredentialsFile =
    if cfg.garage.environmentFile != null then
      cfg.garage.environmentFile
    else
      "/var/lib/garage/celld.env";
  escapedGarageCredentialsFile = lib.escapeShellArg garageCredentialsFile;
  generateGarageCredentials = pkgs.writeShellApplication {
    name = "celld-generate-garage-credentials";
    runtimeInputs = [ pkgs.openssl ];
    text = ''
            install -d -m 0700 /var/lib/garage
      if [[ ! -e ${escapedGarageCredentialsFile} ]]; then
              access_key="GK$(openssl rand -hex 16)"
              secret_key="$(openssl rand -hex 32)"
              umask 0077
        cat > ${escapedGarageCredentialsFile} <<EOF
      GARAGE_RPC_SECRET=$(openssl rand -hex 32)
      GARAGE_DEFAULT_ACCESS_KEY=$access_key
      GARAGE_DEFAULT_SECRET_KEY=$secret_key
      GARAGE_DEFAULT_BUCKET=${cfg.garage.bucket}
      AWS_ACCESS_KEY_ID=$access_key
      AWS_SECRET_ACCESS_KEY=$secret_key
      EOF
            fi
    '';
  };
  formatAddress = address: if lib.hasInfix ":" address then "[${address}]" else address;
  listen = "${formatAddress cfg.listenAddress}:${toString cfg.port}";
  arguments = [
    "--bucket"
    bucket
    "--listen"
    listen
  ]
  ++ optional (endpoint != null) "--endpoint=${endpoint}"
  ++ optional (region != null) "--region=${region}"
  ++ optional (cfg.advertise != null) "--advertise=${cfg.advertise}"
  ++ cfg.extraArgs;
in
{
  options.services.celld = {
    enable = mkEnableOption "celld, a self-hosted distributed Durable Objects runtime";

    package = mkOption {
      type = types.package;
      default = celldPackage;
      defaultText = "the celld package provided by ngp-nur";
      description = "celld package to use.";
    };

    s3 = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            bucket = mkOption {
              type = types.str;
              example = "s3://my-cells-bucket";
              description = "S3 bucket used for deployments, cell state, and fleet coordination.";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "https://example.r2.cloudflarestorage.com";
              description = "Optional endpoint for an S3-compatible object store.";
            };

            region = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "auto";
              description = "Object store region. When unset, celld uses the standard AWS region chain.";
            };
          };
        }
      );
      default = null;
      example = {
        bucket = "s3://my-cells-bucket";
        region = "us-east-1";
      };
      description = ''
        External S3-compatible object store configuration. When this is null,
        the default, the module starts a local single-node Garage instance and
        creates its bucket automatically. Setting this option disables the
        module-managed Garage instance.
      '';
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address on which celld listens for application and peer traffic.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port on which celld listens for application and peer traffic.";
    };

    advertise = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "node-a.internal:8080";
      description = ''
        Address that other celld nodes can reach. This is required by celld
        when listening on an unspecified address such as 0.0.0.0 or ::.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the celld listener port in the firewall.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/run/agenix/celld-aws-credentials" ];
      description = ''
        Files containing environment variables for celld, such as AWS access
        credentials. Paths are passed directly to systemd and are not copied
        to the Nix store.
      '';
    };

    garage = {
      package = mkOption {
        type = types.package;
        default = pkgs.garage_2;
        defaultText = "pkgs.garage_2";
        description = "Garage package to use. Version 2.3 or newer is required.";
      };

      bucket = mkOption {
        type = types.strMatching "[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]";
        default = "celld";
        description = "Name of the bucket automatically created in the local Garage instance.";
      };

      environmentFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/run/agenix/celld-garage-credentials";
        description = ''
          Optional runtime environment file shared by Garage and celld. When
          unset, the module generates persistent credentials in
          /var/lib/garage/celld.env. A supplied file must define
          GARAGE_RPC_SECRET, GARAGE_DEFAULT_ACCESS_KEY,
          GARAGE_DEFAULT_SECRET_KEY, and GARAGE_DEFAULT_BUCKET for Garage, plus
          matching AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY values for celld.
          GARAGE_DEFAULT_BUCKET must match services.celld.garage.bucket.
        '';
      };

      apiAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:3900";
        description = "Garage S3 API listen address used by celld.";
      };

      rpcAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:3901";
        description = "Garage RPC listen address for the single-node object store.";
      };

      settings = mkOption {
        type = types.attrs;
        default = { };
        example = {
          data_dir = [
            {
              path = "/srv/garage/celld";
              capacity = "1T";
            }
          ];
        };
        description = "Additional settings merged into the generated Garage configuration.";
      };
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        CELLD_MAX_RESIDENT_CELLS = "1000";
        CELLD_MAX_RSS_MB = "4096";
        RUST_LOG = "celld=debug";
      };
      description = ''
        Additional environment variables for celld runtime tuning. Values are
        stored in the world-readable Nix store and must not contain secrets.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--unsafe-public-advertise" ];
      description = "Additional command-line arguments passed to celld.";
    };

    user = mkOption {
      type = types.str;
      default = "celld";
      description = "User account under which celld runs.";
    };

    group = mkOption {
      type = types.str;
      default = "celld";
      description = "Group under which celld runs.";
    };
  };

  config = mkIf cfg.enable {
    services.garage = mkIf useGarage {
      enable = true;
      package = cfg.garage.package;
      environmentFile = garageCredentialsFile;
      settings = lib.recursiveUpdate {
        db_engine = "sqlite";
        replication_factor = 1;
        rpc_bind_addr = cfg.garage.rpcAddress;
        rpc_public_addr = cfg.garage.rpcAddress;
        s3_api = {
          api_bind_addr = cfg.garage.apiAddress;
          s3_region = "garage";
          root_domain = ".s3.garage.localhost";
        };
      } cfg.garage.settings;
    };

    systemd.services = {
      celld-garage-credentials = mkIf (useGarage && cfg.garage.environmentFile == null) {
        description = "Generate credentials for celld's local Garage instance";
        requiredBy = [ "garage.service" ];
        before = [ "garage.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = getExe generateGarageCredentials;
          StateDirectory = "garage";
          UMask = "0077";
        };
      };

      garage.serviceConfig.ExecStart = mkIf useGarage (
        mkForce "${getExe cfg.garage.package} server --single-node --default-bucket"
      );
    };

    users.users = mkIf (cfg.user == "celld") {
      celld = {
        isSystemUser = true;
        group = cfg.group;
        description = "celld service user";
      };
    };
    users.groups = mkIf (cfg.group == "celld") { celld = { }; };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.celld = {
      description = "Self-hosted distributed Durable Objects runtime";
      documentation = [ "https://celld.dev/docs" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ] ++ optional useGarage "garage.service";
      requires = optional useGarage "garage.service";
      environment = {
        CELLD_ASSET_CACHE_DIR = "/var/cache/celld/assets";
        CELLD_WATCH = "/var/lib/celld/state";
      }
      // cfg.environment;
      serviceConfig = {
        ExecStart = "${getExe cfg.package} ${escapeShellArgs arguments}";
        EnvironmentFile = cfg.environmentFiles ++ optional useGarage garageCredentialsFile;
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "celld";
        CacheDirectory = "celld";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";

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
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
