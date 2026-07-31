{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ngp.reimsVgpu;
  reimsVgpuPackage = pkgs.callPackage ../pkgs/reims-vgpu { };
in
{
  options.ngp.reimsVgpu = {
    enable = lib.mkEnableOption "the experimental Reims vGPU QEMU build for macOS guests";

    package = lib.mkOption {
      type = lib.types.package;
      default = reimsVgpuPackage;
      defaultText = "the Reims vGPU package provided by ngp-nur";
      description = "Patched QEMU package that provides reims-vgpu-pci.";
    };

    ignoreMsrs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure KVM to ignore unhandled MSRs, which macOS guests require.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64;
        message = "ngp.reimsVgpu supports x86_64 Linux hosts only.";
      }
    ];

    boot.kernelModules = [ "kvm" ];
    boot.extraModprobeConfig = lib.mkIf cfg.ignoreMsrs "options kvm ignore_msrs=1";
    hardware.graphics.enable = true;
    environment.systemPackages = [ cfg.package ];
  };
}
