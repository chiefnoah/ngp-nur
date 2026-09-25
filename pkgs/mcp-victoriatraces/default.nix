{
  fetchurl,
  lib,
  stdenv,
  gnutar,
}:

let
  version = "1.5.0";
  artifacts = {
    "aarch64-linux" = {
      arch = "arm64";
      hash = "sha256-hRfLAEFkeUB12yeZDfk1rIPUAVcG/TZwKOzUOTWOj+Y=";
    };
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-vQ+SI0yvw3lId8YIElP8BEj/mT6daTu3wpOA5MG2DeA=";
    };
  };
  artifact = artifacts.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "mcp-victoriatraces";
  inherit version;

  src = fetchurl {
    url = "https://github.com/VictoriaMetrics/mcp-victoriatraces/releases/download/v${version}/mcp-victoriatraces_Linux_${artifact.arch}.tar.gz";
    inherit (artifact) hash;
  };

  nativeBuildInputs = [ gnutar ];
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    tar -xzf $src -C $out/bin mcp-victoriatraces

    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    export VT_INSTANCE_ENTRYPOINT=http://127.0.0.1:10428
    $out/bin/mcp-victoriatraces --version
  '';

  meta = {
    description = "MCP server for VictoriaTraces";
    homepage = "https://github.com/VictoriaMetrics/mcp-victoriatraces";
    license = lib.licenses.asl20;
    mainProgram = "mcp-victoriatraces";
    platforms = builtins.attrNames artifacts;
  };
}
