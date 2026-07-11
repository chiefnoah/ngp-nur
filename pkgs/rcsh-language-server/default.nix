{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm_11,
  pnpmConfigHook,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rcsh-language-server";
  version = "5.7.0";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "rcsh-language-server";
    rev = "c1ec6750282887c538d13472ee9acb05f2cd357b";
    hash = "sha256-SQYeQiNXcoRgF+yOgKB8vZjRVJzPW+otdQNliUUxTuA=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-2U8d0BKmKaVRyuGlxu5WZjObkHvdU6vS5bxU0mTOh2o=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpmConfigHook
    pnpm_11
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
