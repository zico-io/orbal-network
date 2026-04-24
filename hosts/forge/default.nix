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

  orbal.vm-guest.enable = true;

  orbal.dev.enable = true;

  orbal.languages = {
    node.enable = true;
    go.enable = true;
    rust.enable = true;
    python.enable = true;
  };

  orbal.claude = {
    enable = true;
    agentSkills = {
      enable = true;
      skills = [ "skill-creator" "mcp-builder" "claude-api" ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    22 # SSH (already open via base, explicit for clarity)
  ];
}
