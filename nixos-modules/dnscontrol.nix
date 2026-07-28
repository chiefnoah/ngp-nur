{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ngp.dnscontrol;
  dnscontrolPackage = pkgs.callPackage ../pkgs/dnscontrol { };

  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    escapeShellArg
    filter
    flatten
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    optionals
    types
    unique
    ;

  recordType = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "A";
        description = "DNSControl domain modifier to call.";
      };

      args = mkOption {
        type = types.listOf types.anything;
        default = [ ];
        example = [
          "www"
          "192.0.2.1"
        ];
        description = "JSON-compatible positional arguments passed to the domain modifier.";
      };

      ttl = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 3600;
        description = "Optional TTL() record modifier.";
      };

      metadata = mkOption {
        type = types.attrs;
        default = { };
        description = "Optional provider-specific metadata appended as a JavaScript object.";
      };

      expression = mkOption {
        type = types.nullOr types.lines;
        default = null;
        example = ''IGNORE("dynamic", "A")'';
        description = "Raw DNSControl domain modifier. This is mutually exclusive with type, args, ttl, and metadata.";
      };
    };
  };

  zoneType = types.submodule {
    options = {
      registrar = mkOption {
        type = types.str;
        default = "none";
        description = "Credential name passed to NewRegistrar().";
      };

      dnsProviders = mkOption {
        type = types.nonEmptyListOf types.str;
        description = "Credential names passed to NewDnsProvider().";
      };

      defaultTTL = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Optional DefaultTTL() domain modifier.";
      };

      modifiers = mkOption {
        type = types.listOf types.lines;
        default = [ ];
        example = [ "NO_PURGE" ];
        description = "Raw DNSControl domain modifiers inserted before records.";
      };

      records = mkOption {
        type = types.listOf recordType;
        default = [ ];
        description = "DNS records and other domain modifiers.";
      };
    };
  };

  providerType = types.submodule {
    options = {
      type = mkOption {
        type = types.str;
        example = "PORKBUN";
        description = "DNSControl provider TYPE.";
      };

      settings = mkOption {
        type = types.attrs;
        default = { };
        example = {
          api_key = "$PORKBUN_API_KEY";
          secret_key = "$PORKBUN_SECRET_API_KEY";
        };
        description = ''
          Non-secret provider settings written to the Nix store. Environment
          variable references such as $TOKEN are safe; literal secrets are not.
        '';
      };

      secretFiles = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example.api_key = "/run/agenix/dns-api-key";
        description = ''
          Provider fields read from files at runtime. This is intended for
          agenix, sops-nix, and systemd credentials. File contents never enter
          the Nix store.
        '';
      };
    };
  };

  renderRecord =
    record:
    if record.expression != null then
      record.expression
    else
      let
        arguments =
          (map builtins.toJSON record.args)
          ++ optional (record.ttl != null) "TTL(${toString record.ttl})"
          ++ optional (record.metadata != { }) (builtins.toJSON record.metadata);
      in
      "${record.type}(${concatStringsSep ", " arguments})";

  renderZone =
    domain: zone:
    let
      providers = map (
        provider: "DnsProvider(NewDnsProvider(${builtins.toJSON provider}))"
      ) zone.dnsProviders;
      modifiers =
        optional (zone.defaultTTL != null) "DefaultTTL(${toString zone.defaultTTL})"
        ++ zone.modifiers
        ++ map renderRecord zone.records;
      arguments = [
        (builtins.toJSON domain)
        "NewRegistrar(${builtins.toJSON zone.registrar})"
      ]
      ++ providers
      ++ modifiers;
    in
    ''
      D(
        ${concatMapStringsSep ",\n  " (argument: argument) arguments}
      );
    '';

  generatedConfigText = concatStringsSep "\n" (
    optional (cfg.extraConfig != "") cfg.extraConfig ++ mapAttrsToList renderZone cfg.zones
  );

  uncheckedConfig = pkgs.writeText "dnsconfig.js" generatedConfigText;
  generatedConfig =
    pkgs.runCommand "dnscontrol-checked-config" { nativeBuildInputs = [ cfg.package ]; }
      ''
        dnscontrol check --config ${uncheckedConfig}
        cp ${uncheckedConfig} $out
      '';
  configFile = if cfg.configFile != null then cfg.configFile else generatedConfig;

  usesNoneRegistrar = lib.any (zone: zone.registrar == "none") (lib.attrValues cfg.zones);
  generatedCredentials =
    optionalAttrs usesNoneRegistrar { none.TYPE = "NONE"; }
    // mapAttrs (_: provider: provider.settings // { TYPE = provider.type; }) cfg.providers;
  credentialsTemplate = (pkgs.formats.json { }).generate "dnscontrol-creds.json" generatedCredentials;

  providerSecretFiles = flatten (
    mapAttrsToList (
      providerName: provider:
      mapAttrsToList (field: file: {
        inherit
          field
          file
          providerName
          ;
      }) provider.secretFiles
    ) cfg.providers
  );
  hasSecretFiles = providerSecretFiles != [ ];

  environmentSetup = lib.optionalString (cfg.environmentFiles != [ ]) ''
    if [[ ''${NGP_DNSCONTROL_ENVIRONMENT_LOADED:-0} != 1 ]]; then
      ${concatMapStringsSep "\n" (file: ''
        set -a
        # shellcheck disable=SC1091
        source ${escapeShellArg file}
        set +a
      '') cfg.environmentFiles}
    fi
  '';

  secretFileSetup = concatMapStringsSep "\n" (
    secret:
    let
      provider = escapeShellArg secret.providerName;
      field = escapeShellArg secret.field;
      file = escapeShellArg secret.file;
    in
    ''
      value=$(<${file})
      ${pkgs.jq}/bin/jq \
        --arg provider ${provider} \
        --arg field ${field} \
        --arg value "$value" \
        '.[$provider][$field] = $value' \
        "$credentials" > "$credentials.next"
      mv "$credentials.next" "$credentials"
    ''
  ) providerSecretFiles;

  runtimeCredentialsSetup =
    if cfg.credentialsFile != null then
      "credentials=${escapeShellArg cfg.credentialsFile}"
    else if hasSecretFiles then
      ''
        credentials=$(mktemp)
        trap 'rm -f "$credentials" "$credentials.next"' EXIT
        cp ${credentialsTemplate} "$credentials"
        chmod 600 "$credentials"
        ${secretFileSetup}
      ''
    else
      "credentials=${credentialsTemplate}";

  mkCommand =
    command:
    pkgs.writeShellApplication {
      name = "dnscontrol-${command}";
      runtimeInputs = optionals hasSecretFiles [ pkgs.coreutils ];
      text = ''
        ${environmentSetup}
        ${runtimeCredentialsSetup}
        ${cfg.package}/bin/dnscontrol ${command} \
          --config ${escapeShellArg (toString configFile)} \
          --creds "$credentials" \
          --full "$@"
      '';
    };

  previewCommand = mkCommand "preview";
  pushCommand = mkCommand "push";

  referencedProviders = unique (
    flatten (
      mapAttrsToList (
        _: zone: optionals (zone.registrar != "none") [ zone.registrar ] ++ zone.dnsProviders
      ) cfg.zones
    )
  );
  missingProviders = filter (
    provider: !(builtins.hasAttr provider cfg.providers)
  ) referencedProviders;

  records = flatten (mapAttrsToList (_: zone: zone.records) cfg.zones);
  invalidRecords = filter (
    record:
    (record.expression == null && record.type == null)
    || (
      record.expression != null
      && (record.type != null || record.args != [ ] || record.ttl != null || record.metadata != { })
    )
  ) records;

  serviceConfig = {
    Type = "oneshot";
    User = cfg.user;
    Group = cfg.group;
    UMask = "0077";
    PrivateTmp = true;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    EnvironmentFile = cfg.environmentFiles;
  };
in
{
  options.ngp.dnscontrol = {
    enable = mkEnableOption "declarative DNS management with DNSControl";

    package = mkOption {
      type = types.package;
      default = dnscontrolPackage;
      defaultText = "the DNSControl package provided by ngp-nur";
      description = "DNSControl package to use. The default includes ngp-nur provider fixes.";
    };

    configFile = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = null;
      example = lib.literalExpression "./dnsconfig.js";
      description = "Existing dnsconfig.js. This is mutually exclusive with extraConfig and zones.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Raw DNSControl JavaScript prepended to generated zones.";
    };

    credentialsFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/run/agenix/dnscontrol-creds";
      description = ''
        Runtime path to a complete creds.json. Use a string path from agenix or
        another secret manager so credentials are not copied to the Nix store.
        This is mutually exclusive with providers.
      '';
    };

    environmentFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/run/agenix/dnscontrol-env" ];
      description = ''
        Runtime dotenv files loaded before DNSControl starts. Provider settings
        may refer to their variables using DNSControl's $VARIABLE syntax.
      '';
    };

    providers = mkOption {
      type = types.attrsOf providerType;
      default = { };
      description = "DNSControl credential definitions used to generate creds.json.";
    };

    zones = mkOption {
      type = types.attrsOf zoneType;
      default = { };
      description = "DNS zones rendered to the DNSControl JavaScript DSL.";
    };

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User for DNSControl systemd services.";
    };

    group = mkOption {
      type = types.str;
      default = "root";
      description = "Group for DNSControl systemd services.";
    };

    apply = {
      enable = mkEnableOption "the DNSControl push systemd service";

      onSwitch = mkEnableOption "applying DNS changes during NixOS switches";

      schedule = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "daily";
        description = "Optional systemd OnCalendar schedule for automatic DNS reconciliation.";
      };

      randomizedDelaySec = mkOption {
        type = types.str;
        default = "15m";
        description = "Random delay applied to scheduled pushes.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null || cfg.extraConfig != "" || cfg.zones != { };
        message = "ngp.dnscontrol requires configFile, extraConfig, or at least one zone.";
      }
      {
        assertion = cfg.configFile == null || (cfg.extraConfig == "" && cfg.zones == { });
        message = "ngp.dnscontrol.configFile is mutually exclusive with extraConfig and zones.";
      }
      {
        assertion = cfg.credentialsFile == null || cfg.providers == { };
        message = "ngp.dnscontrol.credentialsFile is mutually exclusive with providers.";
      }
      {
        assertion = cfg.credentialsFile != null || missingProviders == [ ];
        message = "ngp.dnscontrol zones reference undeclared providers: ${concatStringsSep ", " missingProviders}";
      }
      {
        assertion = lib.all (provider: !(builtins.hasAttr "TYPE" provider.settings)) (
          lib.attrValues cfg.providers
        );
        message = "ngp.dnscontrol provider settings must not contain TYPE; use the provider type option.";
      }
      {
        assertion = invalidRecords == [ ];
        message = "Each ngp.dnscontrol record must set either expression or type-based fields, but not both.";
      }
      {
        assertion = cfg.apply.enable || cfg.apply.schedule == null;
        message = "ngp.dnscontrol.apply.schedule requires apply.enable.";
      }
    ];

    environment.systemPackages = [
      cfg.package
      previewCommand
      pushCommand
    ];

    systemd.services.dnscontrol-preview = {
      description = "Preview declarative DNSControl changes";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment.NGP_DNSCONTROL_ENVIRONMENT_LOADED = "1";
      serviceConfig = serviceConfig // {
        ExecStart = "${previewCommand}/bin/dnscontrol-preview";
      };
    };

    systemd.services.dnscontrol-push = mkIf cfg.apply.enable {
      description = "Apply declarative DNSControl changes";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment.NGP_DNSCONTROL_ENVIRONMENT_LOADED = "1";
      serviceConfig = serviceConfig // {
        ExecStart = "${pushCommand}/bin/dnscontrol-push";
      };
    };

    system.activationScripts.dnscontrol-push = mkIf cfg.apply.onSwitch {
      deps = optional (config.system.activationScripts ? agenix) "agenix";
      text = ''
        if [[ "$NIXOS_ACTION" == switch ]]; then
          ${pushCommand}/bin/dnscontrol-push
        fi
      '';
    };

    systemd.timers.dnscontrol-push = mkIf (cfg.apply.enable && cfg.apply.schedule != null) {
      description = "Periodically apply declarative DNSControl changes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.apply.schedule;
        RandomizedDelaySec = cfg.apply.randomizedDelaySec;
        Persistent = true;
        Unit = "dnscontrol-push.service";
      };
    };
  };
}
