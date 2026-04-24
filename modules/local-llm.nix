{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.local-llm;
in
{
  options.orbal.local-llm = {
    enable = mkEnableOption "Ollama local LLM server (OpenAI-compatible /v1 API, tailscale-only)";

    acceleration = mkOption {
      type = types.enum [ "cpu" "cuda" ];
      default = "cpu";
      description = "Inference backend. CUDA requires a GPU host with nixpkgs.config.cudaSupport = true.";
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "llama3.2:3b" "mistral:7b" ];
      description = "Models to pre-pull at activation. Idempotent via upstream ollama-model-loader.service.";
    };

    port = mkOption {
      type = types.port;
      default = 11434;
      description = "TCP port the Ollama HTTP API listens on.";
    };

    webui = {
      enable = mkEnableOption "Open WebUI chat front-end wired to the local Ollama instance";

      port = mkOption {
        type = types.port;
        default = 8080;
        description = "TCP port the Open WebUI HTTP server listens on.";
      };
    };
  };

  # Tailscale-only exposure is an invariant of three things together:
  #   1. host = "0.0.0.0"           (bind to all interfaces)
  #   2. openFirewall = false       (default iface stays closed)
  #   3. modules/base.nix trusts tailscale0 via networking.firewall.trustedInterfaces
  # If any of those changes, re-verify that the API is not publicly reachable.
  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      port = cfg.port;
      openFirewall = false;
      acceleration = if cfg.acceleration == "cpu" then false else cfg.acceleration;
      loadModels = cfg.models;
    };

    services.open-webui = mkIf cfg.webui.enable {
      enable = true;
      host = "0.0.0.0";
      port = cfg.webui.port;
      openFirewall = false;
      # Upstream's default `environment` carries telemetry-off vars; setting this
      # attrset replaces that default, so re-assert them here alongside the
      # Ollama pointer.
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:${toString cfg.port}";
        SCARF_NO_ANALYTICS = "True";
        DO_NOT_TRACK = "True";
        ANONYMIZED_TELEMETRY = "False";
      };
    };
  };
}
