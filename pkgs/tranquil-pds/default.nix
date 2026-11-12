{
  rustPlatform,
  upstream,
}:
let
  cargoHash = "sha256-r6j925a6PfVKNLg60vxKRVw4rddLsGtQ0G2/KvyGw3Q=";
in
upstream.overrideAttrs (old: {
  inherit cargoHash;
  cargoLock = null;

  # Keep distinct sources for crates with the same name and version.
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (old) pname version src;
    hash = cargoHash;
  };
})
