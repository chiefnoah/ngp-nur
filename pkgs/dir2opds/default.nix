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
    rev = "22e33e57a3ad5b349127db4ebe637ca8cfe06dd0";
    hash = "sha256-pJLWq1uTmR0l3wqLH0c9nIW4XvAJGCdPn+quJZUs6P8=";
  };

  vendorHash = "sha256-OdFSJrP44ir12dYiy4TwLuxKzOFwlTGbIszgqzVqvMw=";

  meta = {
    description = "Serve an ebook directory as an OPDS catalog";
    homepage = "https://github.com/chiefnoah/dir2opds";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dir2opds";
  };
}
