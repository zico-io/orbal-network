{ config, lib, ... }:

with lib;

let
  cfg = config.orbal.dnsResolver;
in
{
  options.orbal.dnsResolver.enable =
    mkEnableOption "dnsmasq authoritative resolver for the .orbal fake TLD (tailnet-only)";

  # Tailnet-only exposure works the same way as other orbal services:
  #   1. dnsmasq binds with interface=tailscale0 + bind-interfaces       (module, forced)
  #   2. port 53 is absent from networking.firewall.allowedTCPPorts/UDP
  #   3. modules/base.nix trusts tailscale0 via networking.firewall.trustedInterfaces
  # Must pair with a Tailscale admin → DNS → Split-DNS entry that
  # routes `.orbal` queries to this host's tailnet IP.
  config = mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        interface = "tailscale0";
        bind-interfaces = true;

        # One line per host: `address=/host.orbal/IP` matches host.orbal AND
        # any subdomain (e.g. ollama.forge.orbal, webui.forge.orbal).
        address = mapAttrsToList
          (host: ip: "/${host}.orbal/${ip}")
          config.orbal.tailnetHosts;

        # Don't leak .orbal queries upstream.
        local = "/orbal/";

        # Forward everything else to Tailscale's resolver so on-host processes
        # that hit dnsmasq still get working DNS for the rest of the internet.
        server = [ "100.100.100.100" ];
      };
    };
  };
}
