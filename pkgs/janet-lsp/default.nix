{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "4a839204c2d090d9f2bd92f2b24ddd5a7d4f75fc";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-gyavqWz+xJ1aytJkC5CCc8GgTE5glEJ3f7ch1/mKJso=";
  };
  flake = import "${src}/flake.nix";
in
(flake.outputs {
  self = src // { shortRev = builtins.substring 0 7 rev; };
  nixpkgs = {
    outPath = pkgs.path;
    inherit (pkgs) lib;
  };
}).packages.${pkgs.stdenv.hostPlatform.system}.janet-lsp
