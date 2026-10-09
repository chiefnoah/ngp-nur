{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.0.13";
  artifacts = {
    "aarch64-darwin" = {
      artifact = "macos-aarch64";
      hash = "sha256-nb7UZdbFbgmjmVdsmL/IBKZ9HCok3674lqdiVlWS+W4=";
    };
    "aarch64-linux" = {
      artifact = "linux-aarch64";
      hash = "sha256-ePaoFxGTodIDP5PRtaKUDqSmIUfa9go3rmcKm/hfEuk=";
    };
    "x86_64-darwin" = {
      artifact = "macos-x86_64";
      hash = "sha256-56kzBP8rWYXsO9+MBcocpngQxJMzUooD0kEUwPbpfyQ=";
    };
    "x86_64-linux" = {
      artifact = "linux-x86_64";
      hash = "sha256-U6OzDOFUEEj4+ktCt7xoFhRmuy43CNsQREmlivOAdDA=";
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
