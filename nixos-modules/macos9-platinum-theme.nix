{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ngp.macos9PlatinumTheme;
  theme = pkgs.callPackage ../pkgs/macos9-platinum-theme { };
in
{
  options.ngp.macos9PlatinumTheme.enable = lib.mkEnableOption "Mac OS 9 Platinum desktop theme assets";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ theme ];
    fonts.packages = [ theme ];
  };
}
