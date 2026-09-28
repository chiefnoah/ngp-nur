{
  fetchurl,
  lib,
  stdenv,
  gnutar,
}:

let
  version = "1.5.0";
  artifacts = {
    "aarch64-darwin" = {
      os = "Darwin";
      arch = "arm64";
      hash = "sha256-kQVrcHnV8z46V89HvC57V+QeO/mz5ja89y1RcX9AFsE=";
    };
    "aarch64-linux" = {
      os = "Linux";
      arch = "arm64";
      hash = "sha256-hRfLAEFkeUB12yeZDfk1rIPUAVcG/TZwKOzUOTWOj+Y=";
    };
    "x86_64-linux" = {
      os = "Linux";
      arch = "x86_64";
      hash = "sha256-vQ+SI0yvw3lId8YIElP8BEj/mT6daTu3wpOA5MG2DeA=";
    };
    "x86_64-darwin" = {
      os = "Darwin";
      arch = "x86_64";
      hash = "sha256-VmaXtzud4Lqd3yfc2UphbLE/EX0uL5oUh5PouUHS+bI=";
    };
  };
  artifact = artifacts.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "mcp-victoriatraces";
  inherit version;

  src = fetchurl {
    url = "https://github.com/VictoriaMetrics/mcp-victoriatraces/releases/download/v${version}/mcp-victoriatraces_${artifact.os}_${artifact.arch}.tar.gz";
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
