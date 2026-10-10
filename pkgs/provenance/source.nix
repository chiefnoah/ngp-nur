let
  pin = builtins.fromJSON (builtins.readFile ./source.json);
in
builtins.fetchTarball {
  url = "${pin.url}/archive/${pin.rev}.tar.gz";
  sha256 = pin.hash;
}
