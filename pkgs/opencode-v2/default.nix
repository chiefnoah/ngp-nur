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
  version = "0.0.0-next-15484";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-mapjBg9u6qvQpvDW8lg5RoYKltS+KoEgWKtKQy/P5eshj5kcSKAJ52dLi2G9yEvvlMIlntQJf9+74Coum0uPYA==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-SJ232S50XOYJP7xuTS6ceWvFa8DnhhA49H4RBzR7Rn0JKj04sOu5fkuZaMsANzYu6wecTMnRin/z8f3VRwSpIA==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-7agFEohRAZSC/nzdlHoC5QT11RCtlU2OXmSZP0EPj+XoBWcdIR5ZTKXzp0GK9Bj3sqeqeZbwouDclhN6b5NsUQ==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-TasA8Wk7r+DfO/9QKcin3pfHk4FRwnUGKD0httMbUyIDUcysffCK7LLCBc0SXuptRlynr6rXlTzv3CEYNqsT0Q==";
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
