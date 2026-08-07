{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.celld;
  celldPackage = pkgs.callPackage ../pkgs/celld { };
  garageFormat = pkgs.formats.toml { };

  inherit (lib)
    attrNames
    attrValues
    concatMapStringsSep
    escapeShellArgs
    filterAttrs
    getExe
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalAttrs
    optionals
    remove
    types
    ;

  formatAddress = address: if lib.hasInfix ":" address then "[${address}]" else address;

  projectType = types.coercedTo types.path (root: { inherit root; }) (
    types.submodule {
      options = {
        root = mkOption {
          type = types.path;
          description = ''
            Source root copied to the Nix store. Use the application repository
            root when the Worker imports shared packages outside its directory.
          '';
        };

        config = mkOption {
          type = types.str;
          default = ".";
          example = "workers/api";
          description = ''
            Path within root to the Wrangler project directory or its
            wrangler.json or wrangler.jsonc file.
          '';
        };
      };
    }
  );

  instanceType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkEnableOption "the ${name} celld instance" // {
          default = true;
        };

        package = mkOption {
          type = types.package;
          default = celldPackage;
          defaultText = "the celld package provided by ngp-nur";
          description = "celld package to use.";
        };

        projects = mkOption {
          type = types.attrsOf projectType;
          default = { };
          example = lib.literalExpression ''
            {
              authentication = {
                root = ./my-application;
                config = "workers/authentication";
              };
              api = {
                root = ./my-application;
                config = "workers/api";
              };
            }
          '';
          description = ''
            Wrangler projects deployed to this instance. Attribute names select
            the primary project and should match each project's Wrangler name.
            A path is shorthand for a project whose root is its project directory.
          '';
        };

        primaryProject = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "api";
          description = ''
            Project exposed on the celld listener. It is deployed last so that
            deploy/current.json selects it. Required when projects is not empty.
          '';
        };

        s3 = mkOption {
          type = types.nullOr (
            types.submodule {
              options = {
                bucket = mkOption {
                  type = types.str;
                  example = "s3://my-cells-bucket";
                  description = "S3 bucket used by this celld fleet.";
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
                  description = "Object store region.";
                };
              };
            }
          );
          default = null;
          description = ''
            External S3-compatible storage. When null, the module starts a
            separate single-node Garage service for this instance.
          '';
        };

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address on which this celld instance listens.";
        };

        port = mkOption {
          type = types.port;
          default = 8080;
          description = "Port on which this celld instance listens.";
        };

        advertise = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "node-a.internal:8080";
          description = "Address that other nodes in this celld fleet can reach.";
        };

        openFirewall = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to open this instance's listener port.";
        };

        environmentFiles = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "/run/agenix/celld-aws-credentials" ];
          description = "Runtime environment files, including external S3 credentials.";
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
            default = name;
            defaultText = "the celld instance name";
            description = "Bucket created for this instance's local Garage service.";
          };

          environmentFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Optional credentials shared by this instance's Garage and celld
              services. By default persistent credentials are generated.
            '';
          };

          apiAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:${toString (config.port + 20000)}";
            defaultText = "127.0.0.1:<instance port + 20000>";
            description = "S3 API listen address for this instance's Garage service.";
          };

          rpcAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:${toString (config.port + 20001)}";
            defaultText = "127.0.0.1:<instance port + 20001>";
            description = "RPC listen address for this instance's Garage service.";
          };

          settings = mkOption {
            type = types.attrs;
            default = { };
            description = "Additional settings merged into this instance's Garage configuration.";
          };
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            CELLD_MAX_RESIDENT_CELLS = "1000";
            RUST_LOG = "celld=debug";
          };
          description = ''
            Non-secret environment variables for this celld instance. Values
            are stored in the world-readable Nix store.
          '';
        };

        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional command-line arguments passed to celld.";
        };

        user = mkOption {
          type = types.str;
          default = "celld";
          description = "User account under which this celld instance runs.";
        };

        group = mkOption {
          type = types.str;
          default = "celld";
          description = "Group under which this celld instance runs.";
        };
      };
    }
  );

  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;

  instanceConfig =
    name: instance:
    let
      useGarage = instance.s3 == null;
      serviceName = "celld-${name}";
      deployServiceName = "${serviceName}-deploy";
      garageServiceName = "${serviceName}-garage";
      credentialsServiceName = "${garageServiceName}-credentials";
      celldStateDirectory = serviceName;
      garageStateDirectory = garageServiceName;
      bucket = if useGarage then "s3://${instance.garage.bucket}" else instance.s3.bucket;
      endpoint = if useGarage then "http://${instance.garage.apiAddress}" else instance.s3.endpoint;
      region = if useGarage then "garage" else instance.s3.region;
      credentialsFile =
        if instance.garage.environmentFile != null then
          instance.garage.environmentFile
        else
          "/var/lib/${garageStateDirectory}/celld.env";
      environmentFiles = instance.environmentFiles ++ optional useGarage credentialsFile;
      hasProjects = instance.projects != { };
      projectNames = attrNames instance.projects;
      primaryIsValid =
        instance.primaryProject != null && builtins.hasAttr instance.primaryProject instance.projects;
      deploymentOrder =
        if primaryIsValid then
          remove instance.primaryProject projectNames ++ [ instance.primaryProject ]
        else
          projectNames;
      projectSources = mapAttrs (
        projectName: project:
        let
          source = builtins.path {
            path = project.root;
            name = "${serviceName}-${projectName}-source";
          };
        in
        {
          inherit source;
          target = if project.config == "." then source else "${source}/${project.config}";
        }
      ) instance.projects;
      deployArguments =
        projectName:
        [
          "deploy"
          (toString projectSources.${projectName}.target)
          "--bucket"
          bucket
        ]
        ++ optionals (endpoint != null) [
          "--endpoint"
          endpoint
        ]
        ++ optionals (region != null) [
          "--region"
          region
        ];
      deployScript = pkgs.writeShellApplication {
        name = "${deployServiceName}-start";
        text = concatMapStringsSep "\n" (
          projectName: "${getExe instance.package} ${escapeShellArgs (deployArguments projectName)}"
        ) deploymentOrder;
      };
      listen = "${formatAddress instance.listenAddress}:${toString instance.port}";
      arguments = [
        "--bucket"
        bucket
        "--listen"
        listen
      ]
      ++ optionals (endpoint != null) [
        "--endpoint"
        endpoint
      ]
      ++ optionals (region != null) [
        "--region"
        region
      ]
      ++ optionals (instance.advertise != null) [
        "--advertise"
        instance.advertise
      ]
      ++ instance.extraArgs;
      garageConfig = garageFormat.generate "${garageServiceName}.toml" (
        lib.recursiveUpdate {
          metadata_dir = "/var/lib/${garageStateDirectory}/meta";
          data_dir = "/var/lib/${garageStateDirectory}/data";
          db_engine = "sqlite";
          replication_factor = 1;
          rpc_bind_addr = instance.garage.rpcAddress;
          rpc_public_addr = instance.garage.rpcAddress;
          s3_api = {
            api_bind_addr = instance.garage.apiAddress;
            s3_region = "garage";
            root_domain = ".s3.garage.localhost";
          };
        } instance.garage.settings
      );
      generateCredentials = pkgs.writeShellApplication {
        name = "${credentialsServiceName}-start";
        runtimeInputs = [ pkgs.openssl ];
        text = ''
          install -d -m 0700 /var/lib/${garageStateDirectory}
          if [[ ! -e ${lib.escapeShellArg credentialsFile} ]]; then
            access_key="GK$(openssl rand -hex 16)"
            secret_key="$(openssl rand -hex 32)"
            umask 0077
            cat > ${lib.escapeShellArg credentialsFile} <<EOF
          GARAGE_RPC_SECRET=$(openssl rand -hex 32)
          GARAGE_DEFAULT_ACCESS_KEY=$access_key
          GARAGE_DEFAULT_SECRET_KEY=$secret_key
          GARAGE_DEFAULT_BUCKET=${instance.garage.bucket}
          AWS_ACCESS_KEY_ID=$access_key
          AWS_SECRET_ACCESS_KEY=$secret_key
          EOF
          fi
        '';
      };
      commonHardening = {
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
    in
    {
      assertions = [
        {
          assertion = builtins.match "[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]" name != null;
          message = "services.celld instance name ${name} must be a valid S3 bucket name";
        }
        {
          assertion = !hasProjects || primaryIsValid;
          message = "services.celld.instances.${name}.primaryProject must name a configured project";
        }
        {
          assertion = lib.all (
            project:
            project.config == "."
            || (
              !lib.hasPrefix "/" project.config
              && lib.all (component: component != "" && component != "." && component != "..") (
                lib.splitString "/" project.config
              )
            )
          ) (attrValues instance.projects);
          message = "services.celld.instances.${name} project config paths must stay within their source roots";
        }
        {
          assertion = !useGarage || instance.port <= 45534;
          message = "services.celld.instances.${name}.port must be at most 45534 with local Garage defaults";
        }
      ];

      systemd.services = {
        ${serviceName} = {
          description = "Self-hosted distributed Durable Objects runtime (${name})";
          documentation = [ "https://celld.dev/docs" ];
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
          ]
          ++ optional useGarage "${garageServiceName}.service"
          ++ optional hasProjects "${deployServiceName}.service";
          requires =
            optional useGarage "${garageServiceName}.service"
            ++ optional hasProjects "${deployServiceName}.service";
          restartTriggers =
            map (project: project.source) (attrValues projectSources) ++ optional hasProjects deployScript;
          environment = {
            CELLD_ASSET_CACHE_DIR = "/var/cache/${celldStateDirectory}/assets";
            CELLD_WATCH = "/var/lib/${celldStateDirectory}/state";
          }
          // instance.environment;
          serviceConfig = commonHardening // {
            ExecStart = "${getExe instance.package} ${escapeShellArgs arguments}";
            EnvironmentFile = environmentFiles;
            User = instance.user;
            Group = instance.group;
            StateDirectory = celldStateDirectory;
            CacheDirectory = celldStateDirectory;
            Restart = "on-failure";
            RestartSec = "5s";
            UMask = "0077";
          };
        };
      }
      // optionalAttrs hasProjects {
        ${deployServiceName} = {
          description = "Deploy Wrangler projects for celld instance ${name}";
          documentation = [ "https://celld.dev/docs" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ] ++ optional useGarage "${garageServiceName}.service";
          requires = optional useGarage "${garageServiceName}.service";
          before = [ "${serviceName}.service" ];
          environment = instance.environment;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = getExe deployScript;
            EnvironmentFile = environmentFiles;
            User = instance.user;
            Group = instance.group;
            UMask = "0077";
          };
        };
      }
      // optionalAttrs useGarage {
        ${garageServiceName} = {
          description = "Garage object storage for celld instance ${name}";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
          ]
          ++ optional (instance.garage.environmentFile == null) "${credentialsServiceName}.service";
          requires = optional (instance.garage.environmentFile == null) "${credentialsServiceName}.service";
          restartTriggers = [
            garageConfig
          ]
          ++ optional (instance.garage.environmentFile != null) credentialsFile;
          environment = {
            GARAGE_CONFIG_FILE = garageConfig;
            RUST_LOG = "garage=info";
          };
          serviceConfig = {
            ExecStart = "${getExe instance.garage.package} server --single-node --default-bucket";
            EnvironmentFile = credentialsFile;
            StateDirectory = garageStateDirectory;
            DynamicUser = true;
            ProtectHome = true;
            NoNewPrivileges = true;
            Restart = "on-failure";
            RestartSec = "5s";
            LimitNOFILE = 42000;
          };
        };
      }
      // optionalAttrs (useGarage && instance.garage.environmentFile == null) {
        ${credentialsServiceName} = {
          description = "Generate Garage credentials for celld instance ${name}";
          before = [ "${garageServiceName}.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = getExe generateCredentials;
            StateDirectory = garageStateDirectory;
            UMask = "0077";
          };
        };
      };
    };

  generatedInstances = mapAttrs instanceConfig enabledInstances;
in
{
  options.services.celld.instances = mkOption {
    type = types.attrsOf instanceType;
    default = { };
    description = "Named celld application fleets.";
  };

  config = {
    assertions = [
      {
        assertion =
          lib.length (lib.unique (map (instance: instance.port) (attrValues enabledInstances)))
          == lib.length (attrValues enabledInstances);
        message = "Enabled services.celld instances must use distinct listener ports";
      }
    ]
    ++ lib.concatMap (instance: instance.assertions) (attrValues generatedInstances);

    systemd.services = mkMerge (
      map (instance: instance.systemd.services) (attrValues generatedInstances)
    );

    users.users.celld =
      mkIf (lib.any (instance: instance.user == "celld") (attrValues enabledInstances))
        {
          isSystemUser = true;
          group = "celld";
          description = "celld service user";
        };
    users.groups.celld = mkIf (lib.any (instance: instance.group == "celld") (
      attrValues enabledInstances
    )) { };

    networking.firewall.allowedTCPPorts = mapAttrsToList (_: instance: instance.port) (
      filterAttrs (_: instance: instance.openFirewall) enabledInstances
    );
  };
}
