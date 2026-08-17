{
  autoPatchelfHook,
  buildNpmPackage,
  cacert,
  fd,
  fetchurl,
  lib,
  makeWrapper,
  nodejs_22,
  ripgrep,
  stdenv,
  uv,
}:

let
  buildNpmPackage' = buildNpmPackage.override { nodejs = nodejs_22; };
  platform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  version = "0.7.2";
in
buildNpmPackage' {
  pname = "prime-agent";
  inherit version;

  src = fetchurl {
    url = "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v${version}/prime-agent-${version}.tgz";
    hash = "sha256-vFRx8qYm1ye4ikXrdF//k7EMVUo8T8WRLyXYxkuYf14=";
  };

  sourceRoot = "package";
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-ugHe18fQUuG/XkBUzRyjVbPtrM6GAMVYWOnX5+Xxl6A=";
  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  postInstall = ''
    nodeModules=$out/lib/node_modules/prime-agent/node_modules
    find "$nodeModules/zeromq/build" -mindepth 1 -maxdepth 1 -type d ! -name ${platform} -exec rm -rf '{}' +
    find "$nodeModules/zeromq/build/${platform}" -mindepth 1 -maxdepth 1 -type d ! -name ${arch} -exec rm -rf '{}' +
    find "$nodeModules/koffi/build/koffi" -mindepth 1 -maxdepth 1 -type d ! -name ${platform}_${arch} -exec rm -rf '{}' +
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      find "$nodeModules/zeromq/build/linux/${arch}" -type d -name 'musl-*' -prune -exec rm -rf '{}' +
    ''}

    wrapProgram $out/bin/prime-agent \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          ripgrep
          uv
        ]
      } \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME="$TMPDIR" $out/bin/prime-agent --version 2>&1 | grep -Fx ${lib.escapeShellArg version}
    runHook postInstallCheck
  '';

  meta = {
    description = "Self-improving RLM agent for coding and long-running autonomous tasks";
    homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
    changelog = "https://github.com/PrimeIntellect-ai/prime-agent/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "prime-agent";
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  };
}
