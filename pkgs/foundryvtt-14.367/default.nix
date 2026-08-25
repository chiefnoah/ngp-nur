{
  brotli,
  buildPackages,
  gzip,
  lib,
  makeWrapper,
  nodejs_24,
  openssl,
  requireFile,
  unzip,
  zstd,
}:
let
  version = "14.0.0+367";
  archive = requireFile {
    name = "FoundryVTT-Linux-14.367.zip";
    hash = "sha256-4alroX9IsHDXsl9US82ZF/s6Hia4I+q0laF4nnsPCCQ=";
    url = "https://foundryvtt.com";
  };

  fetchNpmDeps =
    args:
    buildPackages.fetchNpmDeps (
      args
      // {
        buildInputs = [ unzip ];
        setSourceRoot = "sourceRoot=$(pwd)/resources/app";
      }
    );
  buildNpmPackage = buildPackages.buildNpmPackage.override { inherit fetchNpmDeps; };

  application = buildNpmPackage {
    pname = "foundryvtt";
    inherit version;
    src = archive;
    nodejs = nodejs_24;
    npmDepsHash = "sha256-pP4nT9obJz1nmTi6bIZezvggJ61B7tz7HrMPAyLcNfk=";

    postPatch = ''
      install -m644 ${./package-lock.json} package-lock.json
    '';
    setSourceRoot = "sourceRoot=$(pwd)/resources/app";
    makeCacheWritable = true;
    dontNpmBuild = true;

    buildInputs = [ openssl ];
    nativeBuildInputs = [
      makeWrapper
      unzip
      gzip
      zstd
      brotli
    ];
    outputs = [
      "out"
      "gzip"
      "zstd"
      "brotli"
    ];

    postInstall = ''
      foundryvtt=$out/lib/node_modules/foundryvtt
      mkdir -p "$out/bin" "$out/libexec"
      ln -s "$foundryvtt/main.js" "$out/libexec/foundryvtt"
      chmod a+x "$out/libexec/foundryvtt"
      makeWrapper "$out/libexec/foundryvtt" "$out/bin/foundryvtt" \
        --prefix PATH : "${lib.getBin openssl}/bin"
      ln -s "$foundryvtt/public" "$out/public"

      for method in gzip zstd brotli; do
        mkdir -p ''${!method}
        cp -R "$foundryvtt/public/"* ''${!method}
        find ''${!method} -name '*.png' -delete -or -name '*.jpg' -delete \
          -or -name '*.webp' -delete -or -name '*.wav' -delete -or -name '*.ico' -delete \
          -or -name '*.icns' -delete
      done

      find "$gzip" -type f -exec gzip -9 {} +
      find "$zstd" -type f -exec zstd -19 --rm {} +
      find "$brotli" -type f -exec brotli -9 --rm {} +
    '';

    # Marked unfree so CI (ci.nix) filters it from builds;
    # requires a purchased archive via requireFile.
    meta.license = lib.licenses.unfree;
  };
in
application
