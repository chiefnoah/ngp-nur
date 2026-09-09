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
    rev = "bd6a9a8ed69eea033fce51cce4cabad1bcf08103";
    hash = "sha256-keIIQ+xhlz4JQPNdhMXPVmDukG4s++BPA7xwRR6bvzA=";
  };

  vendorHash = "sha256-OdFSJrP44ir12dYiy4TwLuxKzOFwlTGbIszgqzVqvMw=";

  meta = {
    description = "Serve an ebook directory as an OPDS catalog";
    homepage = "https://github.com/chiefnoah/dir2opds";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dir2opds";
  };
}
