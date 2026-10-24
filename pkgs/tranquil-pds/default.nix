{
  rustPlatform,
  upstream,
}:
let
  cargoHash = "sha256-fjT0cAt7lPD0O2PGNT604dRIczerKjExJvU/L3Yul3c=";
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
