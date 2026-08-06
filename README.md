# ngp-nur

**chiefnoah's [NUR](https://github.com/nix-community/NUR) package repository.**

![Build and populate cache](https://github.com/chiefnoah/ngp-nur/workflows/Build%20and%20populate%20cache/badge.svg)

## Packages

This repository currently exports:

- `chicago95-theme`
- `celld`
- `dnscontrol`
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

The `celld` module runs celld directly as a hardened systemd service. By
default it also starts a native, single-node Garage service, generates
persistent credentials under `/var/lib/garage`, and creates a bucket named
`celld`. No container runtime is used:

```nix
{ inputs, ... }:
{
  imports = [ inputs.ngp-nur.nixosModules.celld ];

  services.celld.enable = true;
}
```

The default Garage instance has replication factor 1 and therefore provides no
redundancy. For a celld fleet or production storage, configure a shared Garage
cluster separately and point every celld node at its S3 API. Setting
`services.celld.s3` selects an external S3-compatible bucket and prevents the
module from starting its local Garage instance:

```nix
{ config, inputs, ... }:
{
  imports = [ inputs.ngp-nur.nixosModules.celld ];

  services.celld = {
    enable = true;
    s3 = {
      bucket = "s3://celld-production";
      endpoint = "https://garage.example.com";
      region = "garage";
    };
    environmentFiles = [ config.age.secrets.celld-s3.path ];
    listenAddress = "0.0.0.0";
    advertise = "node-a.internal:8080";
  };
}
```

The S3 credentials file should define `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`. Peer traffic is not protected by TLS; advertised
addresses should remain on a trusted private network or encrypted overlay.

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
