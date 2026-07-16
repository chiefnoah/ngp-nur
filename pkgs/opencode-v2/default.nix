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
  version = "0.0.0-next-15678";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "cli-darwin-arm64";
      hash = "sha512-RJzrgSzF+CoMnSSEQGpnCm4az6H7YI1UgVkfPVnSPpAluWtGGtlWBHbFxWy+bDAnO4I8MnbPSg9a8Sc9FfBssw==";
    };
    "x86_64-darwin" = {
      artifact = "cli-darwin-x64-baseline";
      hash = "sha512-4oF+Mwo1lHRBPfAB6AEr5P2A3lqBql9V2gbLE1bB22UivOdrfCpA0ZYuzfjhBEGoOkVeqg3oBRGtrD/nSepkFw==";
    };
    "aarch64-linux" = {
      artifact = "cli-linux-arm64";
      hash = "sha512-JMCDA/mN+KFEYZ6d+1dsDTBg5HQwPZqjjfNN6nWQ4IsbrBCf6Uuju8euLRPrGtEY/o2TVZN6A/kn8dTeJRGkyQ==";
    };
    "x86_64-linux" = {
      artifact = "cli-linux-x64";
      hash = "sha512-Z8GXlI/gxKYKLwJh/RZa5xbmzO7yWJkCA5Bg2b89f+il6l7NWOZBwMqPDxictcmnyPXx4P4kwc3BDQJeU2hZuQ==";
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
