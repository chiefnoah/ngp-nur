{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule {
  pname = "dir2opds";
  version = "unstable-2026-09-08";

  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "dir2opds";
    rev = "bb565b260470ed651ee36afa1131623d31a10779";
    hash = "sha256-KXwhmlzBt+LwVGpJlghMpQ5aQOEAc+20LTn/zTYfklU=";
  };

  vendorHash = "sha256-OdFSJrP44ir12dYiy4TwLuxKzOFwlTGbIszgqzVqvMw=";

  meta = {
    description = "Serve an ebook directory as an OPDS catalog";
    homepage = "https://github.com/chiefnoah/dir2opds";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dir2opds";
  };
}
