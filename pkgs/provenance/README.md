# Provenance

The package provides the `appview` and `ui` binaries.
The NixOS module imports the service modules from the same pinned source.

```nix
imports = [ inputs.ngp-nur.nixosModules.provenance ];

services.provenance.appview = {
  enable = true;
  dataDirectory = "/srv/provenance/appview";
  serviceKeyFile = config.age.secrets.provenance-service.path;
  jetstreamReplay = true;
  jetstreamAPIKeyFile = config.age.secrets.jetstream.path;
};

services.provenance.ui = {
  enable = true;
  dataDirectory = "/srv/provenance/ui";
  serviceKeyFile = config.age.secrets.provenance-service.path;
  encryptionKeyFile = config.age.secrets.provenance-encryption.path;
  publicOrigin = "https://provenance.example.com";
};
```

Declare the Agenix secrets separately. Keep runtime paths as strings.
The module uses systemd credentials, not Nix store files, for secrets.
Custom data directories use persistent service users. Existing databases require an explicit move and owner change.

Run `pkgs/provenance/update.rc` to update the commit, source hash, and version.
The `mk update` target includes this script.
The pinned upstream package supplies its Go dependency hash.
