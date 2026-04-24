{ lib, ... }:

with lib;

{
  options.orbal.tailnetHosts = mkOption {
    type = types.attrsOf types.str;
    default = { };
    example = { forge = "100.64.0.1"; seed = "100.64.0.2"; };
    description = ''
      hostname → tailnet IPv4 for every host in the orbal tailnet.
      Source of truth for local DNS resolution under .orbal.
      Run `tailscale status` on any node to read current assignments;
      IPs are stable once assigned, so updates are rare.
    '';
  };

  config.orbal.tailnetHosts = {
    forge = "100.117.183.80";
    seed  = "100.123.139.122";
  };
}
