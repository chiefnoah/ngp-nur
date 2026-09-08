{
  fetchFromGitHub,
  fetchPypi,
  fetchPnpmDeps,
  ffmpeg-headless,
  lib,
  makeWrapper,
  nodejs_24,
  pnpm,
  pnpmConfigHook,
  poppler-utils,
  python313,
  python313Packages,
  stdenv,
}:

let
  js2py = python313Packages.buildPythonPackage {
    pname = "js2py";
    version = "0.74";
    format = "setuptools";
    src = fetchPypi {
      pname = "Js2Py";
      version = "0.74";
      hash = "sha256-OfOmqoRpGA77o8hncnHfJ8MTMv0bRx3xryr1i4e4ly8=";
    };
    dependencies = with python313Packages; [
      pyjsparser
      six
      tzlocal
    ];
    doCheck = false;
  };
  cloudscraper = python313Packages.buildPythonPackage {
    pname = "cloudscraper-enhanced";
    version = "3.0.0";
    pyproject = true;
    src = fetchPypi {
      pname = "cloudscraper_enhanced";
      version = "3.0.0";
      hash = "sha256-gIIkGHawBNaDRaeRG1lMh6asGjH9sTYGEx57HAjqZBg=";
    };
    build-system = with python313Packages; [ setuptools ];
    dependencies = with python313Packages; [
      brotli
      certifi
      js2py
      pycryptodome
      pyopenssl
      pyparsing
      requests
      requests-toolbelt
      websocket-client
    ];
    pythonImportsCheck = [ "cloudscraper" ];
  };
  koboPython = python313.withPackages (_: [ cloudscraper ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "bookorbit";
  version = "2.9.0";

  src = fetchFromGitHub {
    owner = "bookorbit";
    repo = "bookorbit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Dj/H7HWzxscl+uSMGDRgAwLeHDzcZEOM0RsiWrPJjUs=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-NVI9R6n9HIE2VufTcqe4cjZbTK30R/i6dZy39TGH8qs=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs_24
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    pnpm --config.verify-deps-before-run=false --filter client run build-only
    pnpm --config.verify-deps-before-run=false --filter server run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/bookorbit/{client,server/migrations} $out/bin
    cp -r node_modules packages $out/lib/bookorbit/
    cp client/package.json $out/lib/bookorbit/client/
    cp -r server/{dist,node_modules,package.json,bin} $out/lib/bookorbit/server/
    cp -r server/src/db/migrations/. $out/lib/bookorbit/server/migrations/
    cp -r client/dist $out/lib/bookorbit/server/public
    cp -r koreader-plugin $out/lib/bookorbit/koreader-plugin
    chmod +x $out/lib/bookorbit/server/bin/kepubify/*

    makeWrapper ${lib.getExe nodejs_24} $out/bin/bookorbit \
      --chdir $out/lib/bookorbit/server \
      --add-flags dist/main.js \
      --prefix PATH : ${
        lib.makeBinPath [
          ffmpeg-headless
          poppler-utils
        ]
      }
    makeWrapper ${lib.getExe nodejs_24} $out/bin/bookorbit-migrate \
      --chdir $out/lib/bookorbit/server \
      --add-flags dist/scripts/migrate.js

    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    test -f $out/lib/bookorbit/server/public/index.html
    test -f $out/lib/bookorbit/server/migrations/meta/_journal.json
    ${lib.getExe nodejs_24} --check $out/lib/bookorbit/server/dist/main.js
  '';

  passthru = { inherit koboPython; };

  meta = {
    description = "Self-hosted library and reading platform";
    homepage = "https://bookorbit.app";
    changelog = "https://github.com/bookorbit/bookorbit/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "bookorbit";
    platforms = lib.platforms.linux;
  };
})
