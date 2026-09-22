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
  version = "2.0.14";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-rAv4hutXUkS3/kBiw2bYuokXYPKOBuck8D39eAMY3FDsUt5AWgM4X7wW/2dKhz6BgVwc1rgWio5MDYrfvS5png==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-zouKRwlYb0/92G35D6iDWKOb7PoB/nmCL5Oql63CH5PYEq2XwE/AXb1mP7s7TAi26xtCDrl36P/wwJw3GQ5luQ==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-wlTLi73Yj3ms7/OrPjF+3dwWz80sFkYSZvOvsU1uYKF5kzA7MCwCYgRZrQudRw9RQZeKt90uVI0fRtBdIPN+dw==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-YFGnck40hBmD8S785zHi1sCZMVodoyxy615SrEo+YXJj/i92I8ViETodsY6Yde0H0VJk/ZuLu8mrllOA4wbAlQ==";
    };
  };
  inherit (artifacts.${stdenvNoCC.hostPlatform.system}) artifact hash;
  wrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ ripgrep ])
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    (lib.makeLibraryPath [ stdenv.cc.cc.lib ])
  ]
  ++ [
    "--set"
    "OPENCODE_DISABLE_AUTOUPDATE"
    "true"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "opencode-v2";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/${artifact}/-/${artifact}-${version}.tgz";
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

    install -Dm755 bin/opencode $out/bin/opencode
    wrapProgram $out/bin/opencode ${lib.escapeShellArgs wrapperArgs}

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
    description = "OpenCode 2.0";
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
