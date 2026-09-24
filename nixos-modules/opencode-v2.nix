{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.opencode-v2;
  package = pkgs.callPackage ../pkgs/opencode-v2 { };
  arguments = [
    "serve"
    "--hostname"
    cfg.hostname
    "--port"
    (toString cfg.port)
  ]
  ++ lib.concatMap (origin: [
    "--cors"
    origin
  ]) cfg.cors;
  command = "${lib.getExe cfg.package} ${lib.escapeShellArgs arguments}";

  # Load the password at runtime so that secret contents never enter the Nix store.
  startWithPassword = pkgs.writeShellScript "opencode-v2-start" ''
    password=$(${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg cfg.passwordFile})
    if [ -z "$password" ]; then
      echo 'OpenCode password file is empty' >&2
      exit 1
    fi

    export OPENCODE_SERVER_PASSWORD="$password"
    exec ${command}
  '';
in
{
  options.services.opencode-v2 = {
    enable = lib.mkEnableOption "OpenCode V2 API and web server";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = "the opencode-v2 package provided by ngp-nur";
      description = "OpenCode V2 package to run.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "opencode-v2";
      description = "User account that runs OpenCode. Create custom accounts separately.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "opencode-v2";
      description = "Group that runs OpenCode. Create custom groups separately.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/opencode-v2";
      description = "Existing directory from which OpenCode serves projects. The service user needs access to it.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which OpenCode listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4096;
      description = "TCP port on which OpenCode listens.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the OpenCode port in the firewall.";
    };

    password = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Server password. This value enters the Nix store. Use passwordFile for secrets.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/agenix/opencode-password";
      description = "Runtime file containing the server password. The service user must be able to read it.";
    };

    cors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "https://app.example.com" ];
      description = "Additional allowed CORS origins. Each origin produces one --cors flag.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.password == null || cfg.passwordFile == null;
        message = "services.opencode-v2.password and passwordFile cannot both be set";
      }
      {
        assertion = cfg.password == null || cfg.password != "";
        message = "services.opencode-v2.password cannot be empty";
      }
    ];

    systemd.services.opencode-v2 = {
      description = "OpenCode V2 API and web server";
      documentation = [ "https://opencode.ai/v2/docs/cli/web/" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = lib.optionalAttrs (cfg.password != null) {
        OPENCODE_SERVER_PASSWORD = cfg.password;
      };
      serviceConfig = {
        ExecStart = if cfg.passwordFile == null then command else startWithPassword;
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "opencode-v2";
        CacheDirectory = "opencode-v2";
        WorkingDirectory = cfg.workingDirectory;
        Restart = "on-failure";
        UMask = "0077";
        NoNewPrivileges = true;
      };
    };

    users.users.opencode-v2 = lib.mkIf (cfg.user == "opencode-v2") {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/opencode-v2";
      description = "OpenCode V2 service user";
    };
    users.groups.opencode-v2 = lib.mkIf (cfg.group == "opencode-v2") { };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
