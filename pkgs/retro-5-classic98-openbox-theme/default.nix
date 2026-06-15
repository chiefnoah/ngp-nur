{
  cacert,
  curl,
  jq,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "retro-5-classic98-openbox-theme";
  version = "2024-01-03";

  src = stdenvNoCC.mkDerivation {
    name = "Retro-5-Classic-98-ObiWine.obt";
    nativeBuildInputs = [
      curl
      jq
    ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    outputHash = "sha256-UX59X4eiGEQQIDtPJ7pqRlcuLfVc7k31SItL03FdAFw=";
    outputHashMode = "flat";
    buildCommand = ''
      url="$(curl --fail --location --silent \
        "https://api.opendesktop.org/ocs/v1/content/data/1017414?format=json" \
        | jq --raw-output '.data[0].downloadlink1')"
      curl --fail --location --output "$out" "$url"
    '';
  };

  dontBuild = true;
  unpackPhase = ''
    runHook preUnpack

    tar -xzf "$src"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/themes"
    cp -r "Retro 5 (Classic 98) ObiWine" "$out/share/themes/retro-5-classic98-obiwine"

    runHook postInstall
  '';

  meta = {
    description = "Retro 5 Classic/98 ObiWine Openbox theme";
    homepage = "https://store.kde.org/p/1017414/";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
