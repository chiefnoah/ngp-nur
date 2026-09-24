{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.0.11";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "macos-aarch64";
      hash = "sha256-uP4TRSZzom/0dNzb55klvetahYL8sNuJ0GUC8uJQlFo=";
    };
    "aarch64-linux" = {
      artifact = "linux-aarch64";
      hash = "sha256-AGfSFWrDGVb1K7C3tpcicz0nVqNz9HxEVmgbFJC0WP4=";
    };
    "x86_64-darwin" = {
      artifact = "macos-x86_64";
      hash = "sha256-jxPF5tPZd+oTE/wa5U2W1C48WEe73JmZi5kCOwi/GD4=";
    };
    "x86_64-linux" = {
      artifact = "linux-x86_64";
      hash = "sha256-BDigZ98eKw4thfHgGHlbf+Wktfr7N/SlkKczkX5TlDs=";
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
