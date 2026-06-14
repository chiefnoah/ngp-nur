{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "retro-5-classic98-openbox-theme";
  version = "2024-01-03";

  src = fetchurl {
    url = "https://files06.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6MTY1NzE0ODE4NSwibyI6IjEiLCJzIjoiMWU0N2NiZGY1YjVlMTEwYjQxOGVhNmY5MjExYzNmOTI4ODIzNDE3YWQ5ODE3ZTQwN2VhYmU2ZGJkZTZhZjQwYzFjYzBhNGFmN2M4NWQ5NjBhOTk4ZmI0YWYwYjIwN2U2MjZhYTA4NmFlMGU3ZmNmNTM3NmVjNTQ2ZGU5ZjY4NzQiLCJ0IjoxNzgxNDc5MjMyLCJzdGZwIjpudWxsLCJzdGlwIjoiNTAuOTMuMjIxLjIwMSJ9.4mJRgHELmFdjZi185DLPcBfTLkLqUNbtk0oLnifl2gU/Retro-5-Classic-98-ObiWine.obt";
    hash = "sha256-UX59X4eiGEQQIDtPJ7pqRlcuLfVc7k31SItL03FdAFw=";
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
    # Upstream does not publish an explicit license.
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
