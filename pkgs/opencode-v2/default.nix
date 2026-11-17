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
  version = "2.3.0";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-ey2HOWX2DK2YJrKta5a+pcvIlkiCyJJsN7NjkJZPsVg9TDXpQWE1OJLWVFqjxZcWNtaMjvKYlrlCY6g8Z2Lb+A==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-23KB1N3fK4seZ5Dc7izb9UKUqv24SVnEzH2WRU+LDMoEXQJzK/mgqADyBvjYG7J4l2GlB9dZ9Lr1qOWXpXNKvQ==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-1IF1NQFD5mdZ7NcU81UifdYAVKEDAP/J07ylbgE4ZATminS7pOn5SOXVzyOkuN1WLcDzXunkju0hw8hug48wTg==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-8T3K8L6Nd4fSG5BSgofqhmIDQ1ZvzDZZ2J7bFVB9RK1d5Hjqh24IcxgbcwpgGKkdvItrayi4Rl+wrSmhl17FFg==";
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
