{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.0.5";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "macos-aarch64";
      hash = "sha256-K5jMGoXBz16iE/Hfccynn3y/9leT0qhygsBMoBnL0cE=";
    };
    "aarch64-linux" = {
      artifact = "linux-aarch64";
      hash = "sha256-i7zeakElbE+sTgoCIpHPAnQEGeJ6+r3juPReek45Pts=";
    };
    "x86_64-darwin" = {
      artifact = "macos-x86_64";
      hash = "sha256-DaSpADTBr80lGhossjfqOgATyWWtjCpFt3E2lLUwrYo=";
    };
    "x86_64-linux" = {
      artifact = "linux-x86_64";
      hash = "sha256-1WOdFzJnd0qoIopHS69hmnB2rEGpECORUAfIZRQ0KbE=";
    };
  };
  inherit (artifacts.${stdenvNoCC.hostPlatform.system}) artifact hash;
in
stdenvNoCC.mkDerivation {
  pname = "fx";
  inherit version;

  src = fetchurl {
    url = "https://github.com/vercel-labs/fx/releases/download/v${version}/fx-${artifact}.tar.gz";
    inherit hash;
  };

  sourceRoot = ".";
  dontBuild = true;
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;

  installPhase = ''
    runHook preInstall

    install -Dm755 fx $out/bin/fx
    install -Dm644 LICENSE THIRD_PARTY_NOTICES.md -t $out/share/doc/fx

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/fx --version | grep -Fx ${lib.escapeShellArg version}
    runHook postInstallCheck
  '';

  meta = {
    description = "Tiny, open, embeddable, native coding agent";
    homepage = "https://fx.sh";
    changelog = "https://github.com/vercel-labs/fx/releases/tag/v${version}";
    downloadPage = "https://github.com/vercel-labs/fx/releases";
    license = lib.licenses.asl20;
    mainProgram = "fx";
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
    platforms = builtins.attrNames artifacts;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
