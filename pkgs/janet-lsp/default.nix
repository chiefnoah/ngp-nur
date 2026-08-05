{
  fetchFromGitHub,
  pkgs,
}:

let
  rev = "d445dddbe91ab8214d27db2ea2c222c52e88a526";
  src = fetchFromGitHub {
    owner = "chiefnoah";
    repo = "janet-lsp";
    inherit rev;
    hash = "sha256-7L+W1K1t/gpJ9Bw/RH1TIM4mBoDUo/+j+iWcLE8QqTg=";
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
