{
  cmake,
  fetchFromGitHub,
  lib,
  ninja,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "goose";
  version = "0-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "goose";
    rev = "20e0b0c663bf87462d05e775cefcc9ac74b90ac6";
    hash = "sha256-mfD1WL4yFnKciy356fBe7wZVEP/xzo3VqAyQ/LtEgDo=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];
  cmakeFlags = [
    (lib.cmakeFeature "GOOSE_VERSION" finalAttrs.version)
    (lib.cmakeFeature "GOOSE_TCC_LIB_PATH" "${placeholder "out"}/lib/goose/tcclib")
    (lib.cmakeFeature "GOOSE_BUILTIN_LIBS" "")
  ];
  enableParallelBuilding = true;

  # Install both runtime resources where the compiler already searches for them.
  installPhase = ''
    runHook preInstall
    install -Dm755 goose "$out/bin/goose"
    mkdir -p "$out/lib/goose"
    cp -R tcclib "$out/lib/goose/"
    cp -R ../stdlib "$out/stdlib"
    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    export GOOSE_HOME="$TMPDIR/goose-home"
    cd "$TMPDIR"
    printf 'import std;\nfn main() { print(clamp(3, 1, 9)); }\n' > smoke.goose
    "$out/bin/goose" --version
    "$out/bin/goose" check smoke.goose
    test "$("$out/bin/goose" run smoke.goose)" = 3
    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.rc;

  meta = {
    description = "Goose programming language compiler";
    homepage = "https://github.com/chiefnoah/goose";
    license = [
      lib.licenses.asl20
      lib.licenses.lgpl21Plus
    ];
    mainProgram = "goose";
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
  };
})
