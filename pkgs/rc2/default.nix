{ callPackage, goose }:
let
  pin = builtins.fromJSON (builtins.readFile ./source.json);
  source = builtins.fetchTarball {
    url = "${pin.url}/archive/${pin.rev}.tar.gz";
    sha256 = pin.hash;
  };
in
callPackage "${source}/nix/rc2.nix" {
  inherit goose;
  inherit (pin) version;
}
