{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "memphis98-icon-theme";
  version = "2021-02-18";

  src = fetchFromGitHub {
    owner = "Stanton731";
    repo = "Memphis98";
    rev = "2d7bb5122d9bcc84ced422943ab2abe3a80d0ac9";
    hash = "sha256-Xn17X1NSbm0E5XhCLQTd6aiKrm8XJ3mfMoanlgP1rVc=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/icons/Memphis98"
    cp -r . "$out/share/icons/Memphis98"

    runHook postInstall
  '';

  meta = {
    description = "Windows 98/2000-inspired icon theme for KDE Plasma";
    homepage = "https://github.com/Stanton731/Memphis98";
    # Upstream does not publish an explicit license.
    platforms = lib.platforms.linux;
  };
}
