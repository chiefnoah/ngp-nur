{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule {
  pname = "dir2opds";
  version = "0-unstable-2026-09-09";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "dir2opds";
    rev = "ae8844e98591b4fd6df36b8d49785e11e2dab6c5";
    hash = "sha256-yjqtILIDixtM4uzDdHpCbOfhOo+2cfPIFQbFJAW7ZXw=";
  };

  vendorHash = "sha256-OdFSJrP44ir12dYiy4TwLuxKzOFwlTGbIszgqzVqvMw=";

  meta = {
    description = "Serve an ebook directory as an OPDS catalog";
    homepage = "https://github.com/chiefnoah/dir2opds";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dir2opds";
  };
}
