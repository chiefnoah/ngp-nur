{
  buildGoModule,
  fetchgit,
  fzf,
  lib,
  makeWrapper,
}:

buildGoModule {
  pname = "nixpkgs-search";
  version = "0.1.0";

  src = fetchgit {
    url = "https://tangled.org/ngp.computer/nixpkgs-search";
    rev = "767590ba41174e97f180f8a6d0fbdcf6b4286548";
    hash = "sha256-1ZoFXiLah0wwgPI8K2Ao91XXN+ZhQQ/y+A/5pWu5wow=";
  };

  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/nixpkgs-search" \
      --prefix PATH : ${lib.makeBinPath [ fzf ]}
  '';

  meta = {
    description = "Search nixpkgs from the terminal";
    homepage = "https://git.sr.ht/~chiefnoah/nixpkgs-search";
    license = lib.licenses.mit;
    mainProgram = "nixpkgs-search";
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
  };
}
