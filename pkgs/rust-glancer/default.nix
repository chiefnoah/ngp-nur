{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-glancer";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "rust-glancer";
    repo = "rust-glancer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Rkmwg2YS4Du32HheQdDzTuRIbjum5XWJFA5q8uTuTLE=";
  };

  cargoHash = "sha256-DhleQDl7IAnyhNkIfqbZSdKHEY7SVH8xzkYOKsgCbT8=";
  cargoBuildFlags = [ "--package=rust-glancer" ];
  cargoTestFlags = [ "--package=rust-glancer" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/rust-glancer --version | grep -F 'rust-glancer ${finalAttrs.version}'

    runHook postInstallCheck
  '';

  meta = {
    description = "Lightweight Rust language server";
    homepage = "https://github.com/rust-glancer/rust-glancer";
    changelog = "https://github.com/rust-glancer/rust-glancer/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "rust-glancer";
  };
})
