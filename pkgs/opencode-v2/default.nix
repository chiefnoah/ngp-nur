{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeBinaryWrapper,
  ripgrep,
  stdenv,
  stdenvNoCC,
}:

let
  version = "0.0.0-next-16842";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-Lkkm/bOIz/ScgexcAm6233H7TTD6p1bZOuzDTe3tBVEMshgu7Xyko1Yu0B1kAIqGOwcZWe9IRAKeaOVV1SFRzg==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-4V0aKKl6cEc8cWLcOVDKSmbqYHj9Me7STGj8Aal7NItA4MJhICB0qqcn34uOUWM3cMFeEzHA9K2RW41ZAai2JQ==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-GhuPXEwqCqCO91HHpqq3jyg9/yXT8LhHKoiQ2DjWHuTGj4hE5Zj04BEcXYSn/roiQjC5uqNhjsLX6yyurj/Jfw==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-FoX9MNqEwVJp81HOywPb3zrt5ZUbpVS9xvwhmW2B8VeHogHDWh+SJZB5cKSp4R8kRmPWO6T2u6hrFotbQGBBEw==";
    };
  };
  inherit (artifacts.${stdenvNoCC.hostPlatform.system}) artifact hash;
in
stdenvNoCC.mkDerivation {
  pname = "opencode-v2";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/${artifact}/-/${artifact}-${version}.tgz";
    inherit hash;
  };

  sourceRoot = "package";
  nativeBuildInputs = [
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  dontBuild = true;
  # Bun standalone executables store their application payload after the ELF
  # image. Stripping the binary discards that payload and leaves a plain Bun
  # runtime that only prints Bun's help.
  dontStrip = true;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/opencode2 $out/bin/opencode2
    wrapProgram $out/bin/opencode2 \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      ${lib.optionalString stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}"} \
      --set OPENCODE_DISABLE_AUTOUPDATE true
    ln -s opencode2 $out/bin/opencode

    runHook postInstall
  '';

  installCheckPhase = ''
    export HOME="$TMPDIR"
    $out/bin/opencode --help > help.txt
    grep -q 'opencode' help.txt
    $out/bin/opencode serve --stdio > serve.txt
    grep -q '"url"' serve.txt
    if grep -q 'Bun is a fast JavaScript runtime' help.txt; then
      echo 'opencode payload was removed from the Bun standalone executable' >&2
      exit 1
    fi
  '';

  meta = {
    description = "OpenCode 2.0 beta";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
    platforms = builtins.attrNames artifacts;
  };
}
