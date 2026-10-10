{
  description = "chiefnoah's NUR package repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    tranquil-pds = {
      url = "git+https://tangled.org/tranquil.farm/tranquil-pds";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      tranquil-pds,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = [ pkgs.rc ] ++ self.checks.${system}.pre-commit-check.enabledPackages;
          };
        }
      );
      legacyPackages = forAllSystems (
        system:
        import ./default.nix {
          pkgs = import nixpkgs { inherit system; };
          tranquil-pds = tranquil-pds.packages.${system}.tranquil-pds;
        }
      );
      packages = forAllSystems (
        system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system}
      );
      checks = forAllSystems (
        system:
        {
          tranquil-pds-vendor = self.packages.${system}.tranquil-pds.cargoDeps;
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              check-merge-conflicts.enable = true;
              check-json.enable = true;
              deadnix.enable = true;
              end-of-file-fixer.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              trim-trailing-whitespace.enable = true;
            };
          };
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          dir2opds = nixpkgs.legacyPackages.x86_64-linux.callPackage ./tests/dir2opds.nix { };
          provenance = nixpkgs.legacyPackages.x86_64-linux.callPackage ./tests/provenance.nix { };
        }
      );
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
      nixosModules = import ./nixos-modules;
      # homeModules = import ./home-modules;
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
    };
}
