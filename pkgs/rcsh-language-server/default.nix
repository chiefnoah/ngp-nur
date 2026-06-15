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
    rev = "5a2b2fbd2c96c4a38e74c6f8f6918b292d19d27e";
    hash = "sha256-YSslmf5XGIhW7q3EYYSxl1+pROhidjWERCIb/I/9vvc=";
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
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
  };
})
