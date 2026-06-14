{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rcsh-language-server";
  version = "5.7.0";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "rcsh-language-server";
    rev = "4c3e3219f34f7dfb61d69c1b82b58e2f2c6401ca";
    hash = "sha256-5YuTWTb+/OWVzIFwyNYmjtIDNh7QdnHswMafoUMdj0s=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-IFKbBGOnUTJ/KM9PPDHlEINKu+DPR4tKTDYJGeGfGb8=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  buildPhase = ''
    runHook preBuild

    pnpm exec tsc -b server

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/rcsh-language-server" "$out/bin"
    cp -R . "$out/lib/rcsh-language-server"

    makeWrapper ${lib.getExe nodejs} "$out/bin/rcsh-language-server" \
      --add-flags "$out/lib/rcsh-language-server/server/out/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Language server for the Plan 9 rc shell";
    homepage = "https://github.com/chiefnoah/rcsh-language-server";
    license = lib.licenses.mit;
    mainProgram = "rcsh-language-server";
    maintainers = with lib.maintainers; [ ];
  };
})
