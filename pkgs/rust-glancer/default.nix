{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-glancer";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "rust-glancer";
    repo = "rust-glancer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3oQpIUsBnYL8dt/wUCHsHcK9/kwJxNlSAw8jbkLf6XY=";
  };

  cargoHash = "sha256-snH6iK+hQgnqc24Z7xXmg457mf5R+ujdc4PGgOXK7Vs=";
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
