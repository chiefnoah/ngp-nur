{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.koreader-sync-server;
  package = pkgs.callPackage ../pkgs/koreader-sync-server { };
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
      type = lib.types.port;
      default = 6378;
      description = "Loopback TCP port for the dedicated Redis instance.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the synchronization server port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers.koreader-sync-server = {
      enable = true;
      port = cfg.redisPort;
      appendOnly = true;
      settings.bind = "127.0.0.1";
    };

    systemd.services.koreader-sync-server = {
      description = "KOReader synchronization server";
      documentation = [ "https://github.com/koreader/koreader-sync-server" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "redis-koreader-sync-server.service" ];
      requires = [ "redis-koreader-sync-server.service" ];
      environment = {
        KOSYNC_PORT = toString cfg.port;
        KOSYNC_REDIS_PORT = toString cfg.redisPort;
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
