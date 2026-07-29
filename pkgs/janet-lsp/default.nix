{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "ba7013e77d256cc97c720e2cfcc2c432762c5932";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-+IgI7VQjkG5A+j9eOoyMvxL9dsdf7zSLVWUBYgU5+10=";
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
