{ lib, pkgs, ... }:
let
  source = import ../pkgs/provenance/source.nix;
  package = pkgs.callPackage ../pkgs/provenance { };
in
{
  imports = [
    "${source}/nix/modules/appview.nix"
    "${source}/nix/modules/ui.nix"
  ];

  services.provenance.appview.package = lib.mkDefault package;
  services.provenance.ui.package = lib.mkDefault package;
}
