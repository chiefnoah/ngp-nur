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
  version = "0.0.0-next-15919";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-CZKLqJuVYOop/92r5SMaDFPnrTTW5lQEV1l3P00hqkLGl6IQ0sP7ktkOQTCQscz11e6BRISSxUUNYg7RDT25jw==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-0tpaWISTrJuwnhBv4x/1ksQOlS6czvKbcUrg/PPWzf0M0rik3owFvATfdMQzGXBJMZq57eVTa/86QESGFNV/Aw==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-b1lymKCxB3RTNpPH4gshG/SOoWY0Z+me5No5YFxK19dzcV2JsIUL6H7dTzdu47II2wZEPKXKZuB5QeCNFOAEaQ==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-BdnHvW4atarrPEHpXJd7Ajya/UEvVYdmirLwWfYqwUHzobZOezb9p+leB8oDUbn9DuzdwrW/qtZFDv4MJrTmdw==";
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
      --set OPENCODE_DISABLE_AUTOUPDATE true
    ln -s opencode2 $out/bin/opencode

    runHook postInstall
  '';

  installCheckPhase = ''
    export HOME="$TMPDIR"
    $out/bin/opencode --help > help.txt
    grep -q 'opencode' help.txt
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
