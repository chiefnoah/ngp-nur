# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `overlays`,
# `nixosModules`, `homeModules`, `darwinModules` and `flakeModules`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
}:

{
  # The `lib`, `overlays`, `nixosModules`, `homeModules`,
  # `darwinModules` and `flakeModules` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  # homeModules = { }; # Home Manager modules
  # darwinModules = { }; # nix-darwin modules
  # flakeModules = { }; # flake-parts modules
  overlays = import ./overlays; # nixpkgs overlays

  chicago95-theme = pkgs.callPackage ./pkgs/chicago95-theme { };
  celld = pkgs.callPackage ./pkgs/celld { };
  dnscontrol = pkgs.callPackage ./pkgs/dnscontrol { };
  janet-lsp = pkgs.callPackage ./pkgs/janet-lsp { inherit pkgs; };
  macos9-platinum-theme = pkgs.callPackage ./pkgs/macos9-platinum-theme { };
  memphis98-icon-theme = pkgs.callPackage ./pkgs/memphis98-icon-theme { };
  retro-5-classic98-openbox-theme = pkgs.callPackage ./pkgs/retro-5-classic98-openbox-theme { };
  windows-classic-theme = pkgs.callPackage ./pkgs/windows-classic-theme { };
  windows98-lxqt-theme = pkgs.callPackage ./pkgs/windows98-lxqt-theme { };
  nixpkgs-search = pkgs.callPackage ./pkgs/nixpkgs-search { };
  opencode-v2 = pkgs.callPackage ./pkgs/opencode-v2 { };
  prime-agent = pkgs.callPackage ./pkgs/prime-agent { };
  rcsh-language-server = pkgs.callPackage ./pkgs/rcsh-language-server { };
  tree-sitter-mk = pkgs.callPackage ./pkgs/tree-sitter-mk { };
  tree-sitter-rcsh = pkgs.callPackage ./pkgs/tree-sitter-rcsh { };
}
