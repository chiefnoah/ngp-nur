{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "86d2f5ae15993fa7bcd1a3dca4b96ec368cbede1";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-QiAN+izWCWwlwV36hPPSF0xJ7sJdl8f9DNQZuJhHLmM=";
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
