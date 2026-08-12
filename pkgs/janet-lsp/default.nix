{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "d6de8e01604904982aca912034860fc3f8a239aa";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-zuElLE0P5JGZIgFwrdREUbWZfvl9/ZOkeUn+qeA6xjk=";
  };
  flake = import "${src}/flake.nix";
in
(flake.outputs {
  self = src // { shortRev = builtins.substring 0 7 rev; };
  nixpkgs = {
    outPath = pkgs.path;
    inherit (pkgs) lib;
  };
}).packages.${pkgs.stdenv.hostPlatform.system}.janet-lsp.overrideAttrs (old: {
  checkPhase = builtins.replaceStrings [ "export TMPDIR=/tmp\n" ] [ "" ] old.checkPhase;
})
