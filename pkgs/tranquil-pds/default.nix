{
  rustPlatform,
  upstream,
}:
let
  cargoHash = "sha256-K4wTFCEozwqAoaFFPhN6ZgonPB1FBuFDT9mjNHumHcs=";
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
