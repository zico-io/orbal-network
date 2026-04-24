{ config, lib, ... }:

with lib;

let
  cfg = config.orbal.reverseProxy;
in
{
  options.orbal.reverseProxy = {
    enable = mkEnableOption "Caddy reverse proxy exposing services as <service>.<host>.orbal (tailnet-only, plain HTTP)";

    services = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            description = "Upstream localhost port to proxy to.";
          };
          upstream = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Upstream host to proxy to. Defaults to loopback.";
          };
        };
      });
      default = { };
      example = literalExpression ''
        {
          ollama.port = 11434;
          webui.port  = 8080;
        }
      '';
      description = ''
        Services to proxy. Each attribute produces a Caddy virtualHost
        http://<name>.<hostname>.orbal that reverse-proxies to upstream:port.
      '';
    };
  };

  # Tailscale-only exposure is an invariant of three things together:
  #   1. Caddy binds on 0.0.0.0:80         (NixOS module default)
  #   2. port 80 is absent from networking.firewall.allowedTCPPorts
  #   3. modules/base.nix trusts tailscale0 via networking.firewall.trustedInterfaces
  # If any of those changes, re-verify that the proxy is not publicly reachable.
  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      virtualHosts = mapAttrs'
        (name: svc: nameValuePair
          "http://${name}.${config.networking.hostName}.orbal"
          { extraConfig = "reverse_proxy ${svc.upstream}:${toString svc.port}"; })
        cfg.services;
    };
  };
}
