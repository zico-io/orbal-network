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
      skills = [ "skill-creator" "mcp-builder" "claude-api" "commit-smart" ];
    };
  };

  orbal.local-llm = {
    enable = true;
    webui.enable = true;
    models = [ "llama3.2:3b" ];
  };

  orbal.reverseProxy = {
    enable = true;
    services = {
      ollama.port = 11434; # matches orbal.local-llm.port default
      webui.port  = 8080;  # matches orbal.local-llm.webui.port default
    };
  };

  networking.firewall.allowedTCPPorts = [
    22 # SSH (already open via base, explicit for clarity)
  ];
}
