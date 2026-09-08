{
  pkgs,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "bookorbit";

  nodes.machine = {
    imports = [ ../nixos-modules/bookorbit.nix ];

    environment.etc = {
      "bookorbit/jwt-secret".text = "test-jwt-secret-with-enough-entropy";
      "bookorbit/setup-token".text = "test-setup-token";
    };

    services.bookorbit = {
      enable = true;
      secrets = {
        jwtSecretFile = "/etc/bookorbit/jwt-secret";
        setupBootstrapTokenFile = "/etc/bookorbit/setup-token";
      };
    };

    system.stateVersion = "26.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("bookorbit.service")
    machine.wait_for_open_port(3000)
    machine.succeed("curl --fail http://127.0.0.1:3000/api/v1/health")
    machine.succeed("sudo -u postgres psql bookorbit -Atc '\\dx vector' | grep -F vector")
    machine.succeed("test -d /var/lib/bookorbit/books")
  '';
}
