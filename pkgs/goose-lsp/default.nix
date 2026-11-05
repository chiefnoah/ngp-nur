{
  fetchFromGitHub,
  goose,
  lib,
  python3,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "goose-lsp";
  version = "0-unstable-2026-11-05";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "goose";
    rev = "20e0b0c663bf87462d05e775cefcc9ac74b90ac6";
    hash = "sha256-mfD1WL4yFnKciy356fBe7wZVEP/xzo3VqAyQ/LtEgDo=";
  };

  nativeBuildInputs = [ goose ];
  nativeInstallCheckInputs = [ python3 ];
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export GOOSE_HOME="$TMPDIR/goose-home"
    goose build --cc "$CC" --stdlib "${goose}/stdlib" -o goose-lsp tools/lsp/main.goose
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 goose-lsp "$out/bin/goose-lsp"
    ln -s "${goose}/stdlib" "$out/stdlib"
    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    mkdir -p build
    python3 test/lsp_goose.py --server "$out/bin/goose-lsp"
    python3 nix/check-lsp.py "$out/bin/goose-lsp" "${goose}/stdlib"
    runHook postInstallCheck
  '';

  passthru.updateScript = ./update.rc;

  meta = {
    description = "Goose language server written in Goose";
    homepage = "https://github.com/chiefnoah/goose";
    license = lib.licenses.asl20;
    mainProgram = "goose-lsp";
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
}
