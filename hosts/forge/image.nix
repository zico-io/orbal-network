{ config, lib, pkgs, modulesPath, ... }:

{
  system.build.forgeImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = "auto";
    format = "qcow2";
    partitionTableType = "efi";
    additionalSpace = "2048M";
  };
}
