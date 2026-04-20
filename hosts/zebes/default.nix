{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/containers.nix
    ../../modules/media-stack.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.05";

  networking = {
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [
      32400 # Plex
      8989  # Sonarr
      7878  # Radarr
      9696  # Prowlarr
    ];
  };

  zebes.media-stack = {
    enable = true;
    mediaPath = "/data/media";
    downloadPath = "/data/downloads";
  };
}
