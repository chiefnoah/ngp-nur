{
  autoPatchelfHook,
  esbuild,
  fetchurl,
  gzip,
  lib,
  makeBinaryWrapper,
  stdenv,
}:

let
  version = "0.6.3";
  artifacts = {
    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-bWF8358EnkPKak43xMzl2ONTlcjoazccmE0yun2AO/U=";
    };
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-UISgg0cs8DZVGn6sY/ok0iu5pWMjxRf2MgVyTBJ4MEc=";
    };
  };
  inherit (artifacts.${stdenv.hostPlatform.system}) target hash;
in
stdenv.mkDerivation {
  pname = "celld";
  inherit version;

  src = fetchurl {
    url = "https://github.com/denoland/celld/releases/download/v${version}/celld-${target}.gz";
    inherit hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    gzip
    makeBinaryWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];
  dontUnpack = true;
  dontBuild = true;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    gzip -dc $src > $out/bin/celld
    chmod +x $out/bin/celld
    wrapProgram $out/bin/celld \
      --set CELLD_ESBUILD ${lib.getExe esbuild}

    runHook postInstall
  '';

  installCheckPhase = ''
    $out/bin/celld --version | grep -F 'celld ${version}'
  '';

  meta = {
    description = "Self-hosted, distributed Durable Objects runtime";
    homepage = "https://celld.dev";
    changelog = "https://github.com/denoland/celld/releases/tag/v${version}";
    downloadPage = "https://github.com/denoland/celld/releases";
    license = lib.licenses.asl20;
    mainProgram = "celld";
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
    platforms = builtins.attrNames artifacts;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
