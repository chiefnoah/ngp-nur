{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.koreader-sync-server;
  package = pkgs.callPackage ../pkgs/koreader-sync-server { };
  localRedisPort = 6378;
  useLocalRedis = cfg.redisPort == null;
  redisPort = if cfg.redisPort != null then cfg.redisPort else localRedisPort;
in
{
  options.services.koreader-sync-server = {
    enable = lib.mkEnableOption "KOReader synchronization server";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = "the koreader-sync-server package provided by ngp-nur";
      description = "KOReader synchronization server package.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 17200;
      description = "Loopback TCP port for the synchronization server.";
    };

    redisPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "Existing Redis port. A dedicated Redis instance starts when unset.";
    };

    enableUserRegistration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow KOReader clients to create accounts.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the synchronization server port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers.koreader-sync-server = lib.mkIf useLocalRedis {
      enable = true;
      port = localRedisPort;
      appendOnly = true;
      settings.bind = "127.0.0.1";
    };

    systemd.services.koreader-sync-server = {
      description = "KOReader synchronization server";
      documentation = [ "https://github.com/koreader/koreader-sync-server" ];
      wantedBy = [ "multi-user.target" ];
      after = lib.optional useLocalRedis "redis-koreader-sync-server.service";
      requires = lib.optional useLocalRedis "redis-koreader-sync-server.service";
      environment = {
        ENABLE_USER_REGISTRATION = lib.boolToString cfg.enableUserRegistration;
        KOSYNC_PORT = toString cfg.port;
        KOSYNC_REDIS_PORT = toString redisPort;
      };
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        DynamicUser = true;
        Restart = "on-failure";
        RuntimeDirectory = "koreader-sync-server";
        RuntimeDirectoryMode = "0750";
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
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
