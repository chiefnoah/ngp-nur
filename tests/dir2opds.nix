{
  pkgs,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "dir2opds";

  nodes.machine = {
    imports = [ ../nixos-modules/dir2opds.nix ];

    services.dir2opds = {
      enable = true;
      enableHTML = true;
      pdfCovers.enable = true;
    };

    system.stateVersion = "26.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("dir2opds.service")
    machine.wait_for_open_port(8080)
    machine.succeed("curl --fail http://127.0.0.1:8080/health")
    machine.succeed("curl --fail -H 'Accept: text/html' http://127.0.0.1:8080/ | grep -F '<html'")
    machine.succeed("systemctl show dir2opds.service -P ExecStart | grep -F '/bin/pdftoppm'")
    machine.succeed("test -d /var/lib/dir2opds/books")
    machine.succeed("test -d /var/cache/dir2opds")
  '';
}
