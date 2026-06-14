{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "windows-classic-theme";
  version = "2022-02-23";

  src = fetchFromGitHub {
    owner = "pixelocdguy";
    repo = "windows-classic";
    rev = "84e6af501cf85929c582b6f6d5d2308772e5edec";
    hash = "sha256-qWWbJ/c0gbpyTnR2ckWzybry0UEgDLirCTX4tpYtDnI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/lxqt/themes" "$out/share/themes"
    cp -r lxqt/windows-classic "$out/share/lxqt/themes/windows-classic"
    cp -r openbox/windows-classic "$out/share/themes/windows-classic"

    runHook postInstall
  '';

  meta = {
    description = "Windows Classic-inspired LXQt and Openbox theme";
    homepage = "https://github.com/pixelocdguy/windows-classic";
    # Upstream does not publish an explicit license.
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
