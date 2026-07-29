{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "90167b769b1ee3c4c984853984bfba99fbee794d";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-TvaPrHAFGvGT1ycdJzDvnM4+fMOG+XPshJX9w5yIsDM=";
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
