{ pkgs, ... }:
let
  source = import ../pkgs/provenance/source.nix;
  package = pkgs.callPackage ../pkgs/provenance { };
  system = pkgs.stdenv.hostPlatform.system;
in
pkgs.testers.runNixOSTest (
  import "${source}/nix/tests/services.nix" {
    inherit system;
    self = {
      nixosModules.default = ../nixos-modules/provenance.nix;
      packages.${system} = {
        appview = package;
        ui = package;
      };
    };
  }
)
