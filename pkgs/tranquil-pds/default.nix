{
  rustPlatform,
  upstream,
}:
let
  cargoHash = "sha256-Ys71U939KFMKieqA6zrB6XCCOwJnswrT9yzYQ9bUXis=";
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
