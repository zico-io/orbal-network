{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "virtio_blk" "virtio_pci" "virtio_net" "virtio_scsi" "ahci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/vda2";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/vda1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024; # 8 GiB — overflow for tsc spikes on large monorepos
  }];

  # Keep swap as a last resort; normal workloads stay in RAM.
  boot.kernel.sysctl."vm.swappiness" = 10;

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
