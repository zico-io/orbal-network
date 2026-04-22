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

  networking.firewall.allowedTCPPorts = [
    22 # SSH (already open via base, explicit for clarity)
  ];

  environment.systemPackages = with pkgs; [
    direnv
    nix-direnv
    gcc
    gnumake
    ripgrep
    fd
    unzip
  ];

  programs.direnv.enable = true;
}
