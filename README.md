# ngp-nur

**chiefnoah's [NUR](https://github.com/nix-community/NUR) package repository.**

![Build and populate cache](https://github.com/chiefnoah/ngp-nur/workflows/Build%20and%20populate%20cache/badge.svg)

## Packages

This repository currently exports:

- `chicago95-theme`
- `memphis98-icon-theme`
- `opencode-v2`
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
