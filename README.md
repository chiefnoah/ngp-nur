# ngp-nur

**chiefnoah's [NUR](https://github.com/nix-community/NUR) package repository.**

![Build and populate cache](https://github.com/chiefnoah/ngp-nur/workflows/Build%20and%20populate%20cache/badge.svg)

## Packages

This repository currently exports:

- `chicago95-theme`
- `celld`
- `dnscontrol`
- `foundryvtt_14_367`
- `fx`
- `janet-lsp`
- `memphis98-icon-theme`
- `opencode-v2`
- `prime-agent`
- `retro-5-classic98-openbox-theme`
- `windows-classic-theme`
- `windows98-lxqt-theme`
- `rcsh-language-server`
- `tree-sitter-rcsh`

## Usage

After this repository is registered in community NUR as `chiefnoah`, packages can
be installed from the NUR namespace:

```console
nix shell github:nix-community/NUR#legacyPackages.x86_64-linux.repos.chiefnoah.rcsh-language-server
```

Or from a NixOS configuration using the NUR overlay:

```nix
environment.systemPackages = [
  pkgs.nur.repos.chiefnoah.rcsh-language-server
];
```

## NixOS Modules

### celld

The `celld` module runs named celld application fleets as hardened systemd
services. By default, all instances share one native, single-node Garage
service and its credentials. Each instance gets a bucket matching its name. No
container runtime is used:

```nix
{ inputs, ... }:
{
  imports = [ inputs.ngp-nur.nixosModules.celld ];

  services.celld.instances.hello = {
    port = 8082;
    projects.hello = ./worker;
    primaryProject = "hello";
  };
}
```

The project directory must contain `wrangler.json` or `wrangler.jsonc`. It is
copied to the Nix store, deployed before celld starts, and redeployed when its
source changes. Do not put secrets in project sources because Nix store paths
are readable by local users.

An instance may contain several Wrangler projects connected by service
bindings. Set `primaryProject` to the project that receives incoming requests.
Other projects are deployed first and the primary project is deployed last:

```nix
services.celld.instances.application = {
  port = 8082;
  listenAddress = "0.0.0.0";
  advertise = "odin:8082";

  projects = {
    authentication = {
      root = ./my-application;
      config = "workers/authentication";
    };
    api = {
      root = ./my-application;
      config = "workers/api";
    };
  };
  primaryProject = "api";
};
```

Using a shared source root allows Workers to import packages elsewhere in a
monorepo. A plain path is shorthand for `root = path; config = ".";`.

The shared Garage service listens on `127.0.0.1:3900` by default. Configure it
once through `services.celld.garage`; the module creates every instance bucket
and grants the shared key access automatically:

```nix
services.celld.garage = {
  apiAddress = "127.0.0.1:3900";
  rpcAddress = "127.0.0.1:3901";
  environmentFile = config.age.secrets.celld-garage.path;
};
```

Module-managed Garage has replication factor 1 and provides no redundancy. For
a production fleet, an instance can override the shared default with external
S3-compatible storage:

```nix
{ config, inputs, ... }:
{
  imports = [ inputs.ngp-nur.nixosModules.celld ];

  services.celld.instances.production = {
    port = 8080;
    s3 = {
      bucket = "s3://celld-production";
      endpoint = "https://garage.example.com";
      region = "garage";
    };
    environmentFiles = [ config.age.secrets.celld-s3.path ];
    listenAddress = "0.0.0.0";
    advertise = "node-a.internal:8080";

    projects.api = ./worker;
    primaryProject = "api";
  };
}
```

The S3 credentials file should define `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`. Instance `environmentFiles` are loaded after the
shared Garage credentials, so they may override credentials for that instance.
Peer traffic is not protected by TLS; advertised addresses should remain on a
trusted private network or encrypted overlay.

### DNSControl

The `dnscontrol` module generates provider-neutral DNSControl configuration and
provides `dnscontrol-preview` and `dnscontrol-push` commands. Import it from the
flake and declare providers and zones:

```nix
{ config, inputs, ... }:
{
  imports = [ inputs.ngp-nur.nixosModules.dnscontrol ];

  ngp.dnscontrol = {
    enable = true;

    environmentFiles = [ config.age.secrets.porkbun.path ];
    providers.porkbun = {
      type = "PORKBUN";
      settings = {
        api_key = "$PORKBUN_API_KEY";
        secret_key = "$PORKBUN_SECRET_API_KEY";
      };
    };

    zones."example.com" = {
      registrar = "porkbun";
      dnsProviders = [ "porkbun" ];
      records = [
        {
          type = "A";
          args = [
            "@"
            "192.0.2.1"
          ];
          ttl = 600;
        }
        {
          type = "MX";
          args = [
            "@"
            10
            "mail.example.com."
          ];
        }
      ];
    };
  };
}
```

Secrets may be supplied as a complete runtime `credentialsFile`, through
`environmentFiles`, or as individual `providers.<name>.secretFiles.<field>`
paths. These options accept runtime strings such as agenix paths and do not copy
secret contents to the Nix store.

Run `sudo dnscontrol-preview` before applying changes with
`sudo dnscontrol-push`. DNS is never changed during NixOS activation. An
optional `ngp.dnscontrol.apply` service and timer can automate pushes after the
configuration has been reviewed.

## Local Checks

Run the same restricted evaluation check used by NUR:

```console
nix-env -f . -qa \* --meta --xml \
  --allowed-uris https://static.rust-lang.org \
  --option restrict-eval true \
  --option allow-import-from-derivation true \
  --drv-path --show-trace \
  -I nixpkgs=$(nix-instantiate --find-file nixpkgs) \
  -I "$PWD"
```

Build cacheable outputs locally:

```console
nix-build ci.nix -A cacheOutputs
```

## Registering With NUR

Open a pull request against `nix-community/NUR` that adds this repository to
`repos.json`:

```json
{
  "repos": {
    "chiefnoah": {
      "url": "https://github.com/chiefnoah/ngp-nur"
    }
  }
}
```

Only commit the `repos.json` change in the NUR pull request. The community NUR
automation updates `repos.json.lock`.
