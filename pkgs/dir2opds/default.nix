{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule {
  pname = "dir2opds";
  version = "0-unstable-2026-09-08";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "dir2opds";
    rev = "21ef6ded53d3f57404695e837dae10a8a11dd667";
    hash = "sha256-SbMndcHZ1+lUjG1SMBIlB5Tr8OwRBiv7VKxGxz4tLEQ=";
  };

  vendorHash = "sha256-OdFSJrP44ir12dYiy4TwLuxKzOFwlTGbIszgqzVqvMw=";

  meta = {
    description = "Serve an ebook directory as an OPDS catalog";
    homepage = "https://github.com/chiefnoah/dir2opds";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dir2opds";
  };
}
