{ lib, buildGo126Module }:
let
  source = import ./source.nix;
  pin = builtins.fromJSON (builtins.readFile ./source.json);
in
(import "${source}/nix/package.nix" {
  inherit lib;
  buildGoModule = buildGo126Module;
}).overrideAttrs
  {
    inherit (pin) version;
    __intentionallyOverridingVersion = true;
  }
