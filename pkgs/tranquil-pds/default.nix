{
  rustPlatform,
  upstream,
}:
let
  cargoHash = "sha256-KWXOZZf+oM+oRhjF4/DrZZ1K7aaZ8H3wZSQSl1TLrQM=";
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
