{
  fetchurl,
  lib,
  stdenv,
  gnutar,
}:

let
  version = "1.9.0";
  artifacts = {
    "aarch64-linux" = {
      arch = "arm64";
      hash = "sha256-NcTNvyjqtiwNwWDWQAGn4W9t1faGifhUMOiRSdcrUHg=";
    };
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-ZvaMB/eA7EHJKD3xnR33engkoYMP3NtLal67hPCx+HE=";
    };
  };
  artifact = artifacts.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "mcp-victorialogs";
  inherit version;

  src = fetchurl {
    url = "https://github.com/VictoriaMetrics/mcp-victorialogs/releases/download/v${version}/mcp-victorialogs_Linux_${artifact.arch}.tar.gz";
    inherit (artifact) hash;
  };

  nativeBuildInputs = [ gnutar ];
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    tar -xzf $src -C $out/bin mcp-victorialogs

    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    export VL_INSTANCE_ENTRYPOINT=http://127.0.0.1:9428
    $out/bin/mcp-victorialogs --version
  '';

  meta = {
    description = "MCP server for VictoriaLogs";
    homepage = "https://github.com/VictoriaMetrics/mcp-victorialogs";
    license = lib.licenses.asl20;
    mainProgram = "mcp-victorialogs";
    platforms = builtins.attrNames artifacts;
  };
}
