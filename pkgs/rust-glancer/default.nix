{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-glancer";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "rust-glancer";
    repo = "rust-glancer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3CdKyRsKbMfPBZ2UXgRmj+sKhQMl5GRuT7Pc2VkJpzs=";
  };

  cargoHash = "sha256-88gs9H8HgK8n/Qx2nncJQ/FQEiSmk+7HK8iCxzM+1bA=";
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
