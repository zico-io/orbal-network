{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./image.nix
    ../../modules/vm-guest.nix
    ../../modules/containers.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";

  zebes.vm-guest.enable = true;

  zebes.dev = {
    enable = true;
    languages.node.enable = true;
    languages.go.enable = true;
    languages.rust.enable = true;
    languages.python.enable = true;
  };

  networking.firewall.allowedTCPPorts = [
    22 # SSH (already open via base, explicit for clarity)
  ];
}
