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
  version = "2.0.19";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-0uY/cQqUWOrY0YqGC3islJAEtpseKo7L0aqLWugca6HjLFH4acXdvXf26mIs7lL3tjTd0dzKChlCErKJ4Ebz0g==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-wh3BPpYoW8KfGj36dPfSHJ3rKCZxTiDoNIAqyQUjKJM+L+SXEh1o/NzuifmtVZ6CuLKHw2Se11t++8JX1tET0A==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-i0HOHovWgm8QK6MzEos6V5rDj3dHOOafUdP3cNH4Mc4djULWMAQwfNoygp6QXmlWXatVgUzQt65XHkdCF7VAPA==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-FB/rRN+Lwbipw1eIFWXUSRzGejk13Hh3yP3kKK8hbe62rK5kmvCVnwRxRa3zxqwA6y6iLnPMKrez2uHvpvjW3w==";
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
