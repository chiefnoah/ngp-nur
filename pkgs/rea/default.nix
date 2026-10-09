{
  autoPatchelfHook,
  buildNpmPackage,
  fetchurl,
  lib,
  nodejs_24,
  stdenv,
  testers,
}:

buildNpmPackage (finalAttrs: {
  pname = "rea";
  version = "6.2.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${finalAttrs.version}.tgz";
    hash = "sha256-wWMFztqpj1btBPxwIowhEVg1+qmHYoNWW1L8J+S0nSc=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-oHCs0glqL5FnLWqDfVEuffReGky4Rlcy5G3tGJPCYDU=";

  # The published archive includes compiled code. Pin only its runtime dependencies.
  postPatch = ''
    ${lib.getExe nodejs_24} -e '
      const fs = require("fs");
      const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
      delete pkg.devDependencies;
      fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
    '
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${lib.getExe nodejs_24} ${./check.mjs} "$out" ${lib.escapeShellArg finalAttrs.version}
    runHook postInstallCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
  };

  meta = {
    description = "Reverse engineering CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
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
