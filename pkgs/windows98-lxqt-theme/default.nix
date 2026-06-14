{
  cacert,
  curl,
  jq,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "windows98-lxqt-theme";
  version = "1.0";

  src = stdenvNoCC.mkDerivation {
    name = "windows-98.tar.gz";
    nativeBuildInputs = [
      curl
      jq
    ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    outputHash = "sha256-HwT/s7IM6iENmwQPSjIJYJr6P/DMVC19S1TOKmv5EtY=";
    outputHashMode = "flat";
    buildCommand = ''
      url="$(curl --fail --location --silent \
        "https://api.opendesktop.org/ocs/v1/content/data/2113541?format=json" \
        | jq --raw-output '.data[0].downloadlink1')"
      curl --fail --location --output "$out" "$url"
    '';
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/lxqt/themes"
    cp -r . "$out/share/lxqt/themes/windows-98"

    runHook postInstall
  '';

  meta = {
    description = "Windows 98 LXQt theme";
    homepage = "https://store.kde.org/p/2113541/";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
