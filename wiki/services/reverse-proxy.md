# Reverse proxy (Caddy) and `.orbal` DNS

## Overview

Per-host Caddy reverse proxy exposing tailnet services as `http://<service>.<host>.orbal`. A dnsmasq resolver on `seed` answers every `*.orbal` query inside the tailnet. Both are tailnet-only — plain HTTP is fine because the tailnet is already WireGuard-encrypted end-to-end.

Three modules:

- `modules/tailnet-hosts.nix` — shared attrset `orbal.tailnetHosts` mapping hostname → tailnet IPv4.
- `modules/reverse-proxy.nix` — per-host Caddy. Enabled via `orbal.reverseProxy.enable = true`.
- `modules/dns-resolver.nix` — dnsmasq on tailscale0. Enabled on exactly one host (seed) via `orbal.dnsResolver.enable = true`.

Plus one manual step: a Tailscale admin → DNS → Split-DNS entry for `.orbal` pointing at seed's tailnet IP.

## Why `.orbal` and not `*.ts.net`

Tailscale's built-in ACME (`tailscale cert`) only issues certs for a node's own FQDN — no wildcards, no subdomains. And MagicDNS returns NXDOMAIN for anything under a node name. So `service.host.<tailnet>.ts.net` with HTTPS is not achievable today. See `wiki/decisions/003-orbal-split-dns.md` for the full rationale.

## Option surface

### `orbal.reverseProxy`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orbal.reverseProxy.enable` | bool | `false` | Master toggle on a host. |
| `orbal.reverseProxy.services` | attrsOf { port, upstream } | `{ }` | Each attribute produces a virtualHost `http://<name>.<hostname>.orbal` → `<upstream>:<port>`. |
| `orbal.reverseProxy.services.<name>.port` | port | — | Upstream localhost port. |
| `orbal.reverseProxy.services.<name>.upstream` | str | `"127.0.0.1"` | Upstream host. |

### `orbal.dnsResolver`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orbal.dnsResolver.enable` | bool | `false` | Runs dnsmasq on tailscale0, authoritative for `.orbal`. |

### `orbal.tailnetHosts`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orbal.tailnetHosts` | attrsOf str | populated in the module itself | hostname → tailnet IPv4. Edit `modules/tailnet-hosts.nix` when IPs change or a host is added. |

## Security model

Same three-invariant pattern used by `local-llm`:

1. Caddy binds on `0.0.0.0:80`; dnsmasq binds with `interface = "tailscale0"` + `bind-interfaces = true`.
2. Ports 80 (Caddy) and 53 (dnsmasq) are **not** in `networking.firewall.allowedTCPPorts`.
3. `modules/base.nix` trusts `tailscale0` via `networking.firewall.trustedInterfaces`.

If (3) changes, both the proxy and the resolver become publicly reachable. Audit with the verification steps below whenever `base.nix` is touched.

## Currently enabled

- `hosts/forge/default.nix` — `orbal.reverseProxy.enable = true` with `ollama.port = 11434`, `webui.port = 8080`. URLs: `http://ollama.forge.orbal`, `http://webui.forge.orbal`.
- `hosts/seed/default.nix` — `orbal.dnsResolver.enable = true`.

## Adding a new service

1. Deploy the service on its host in the usual way (e.g. `orbal.<service>.enable = true`).
2. In that host's `default.nix`, add it to `orbal.reverseProxy.services`:
   ```nix
   orbal.reverseProxy.services.<service>.port = <port>;
   ```
3. Rebuild the host. No DNS changes needed — dnsmasq's `address=/host.orbal/IP` record already covers every subdomain.
4. Verify: `curl http://<service>.<host>.orbal/`.

## Adding a new host

1. Add the host to the flake (`flake.nix` `nixosConfigurations`) as usual.
2. Find the host's tailnet IP: `tailscale status` on any node.
3. Append to `orbal.tailnetHosts` in `modules/tailnet-hosts.nix`:
   ```nix
   <hostname> = "100.x.y.z";
   ```
4. Rebuild seed so dnsmasq picks up the new record.
5. On the new host, opt into `orbal.reverseProxy` as needed.

## Split-DNS admin step (one-time)

Tailscale admin console → **DNS** → **Nameservers** → **Add nameserver → Custom**:

- Restrict to domain: `orbal`
- Nameserver IP: seed's tailnet IPv4 (`100.123.139.122` today)

This tells every tailnet client to forward `*.orbal` queries to dnsmasq on seed. It is Tailscale SaaS state and cannot be codified in this repo.

## Verification

After rebuilding seed:

```sh
# From any tailnet client
dig @100.123.139.122 ollama.forge.orbal +short     # → 100.117.183.80
dig @100.123.139.122 webui.forge.orbal  +short     # → 100.117.183.80
dig @100.123.139.122 seed.orbal         +short     # → 100.123.139.122
```

After the Tailscale admin Split-DNS entry is in place:

```sh
dig ollama.forge.orbal +short                      # → 100.117.183.80, via MagicDNS
```

After rebuilding forge:

```sh
curl http://ollama.forge.orbal/api/tags            # JSON of loaded models
curl -I http://webui.forge.orbal/                  # 200 OK from Open WebUI
```

Public-unreachability check (from outside the tailnet, e.g. cellular):

```sh
curl --max-time 5 http://<forge-public-ip>/        # must fail
curl --max-time 5 http://<seed-public-ip>:53       # must fail
```

## Notes

- Plain HTTP: Open WebUI may set Secure cookies; if login misbehaves in a browser, flip to `tls internal` on Caddy (per-host CA, trust on clients) or buy a real domain and move to Cloudflare DNS-01 for real ACME. Tracked as a follow-up — not a problem today.
- Single DNS resolver on seed is a single point of failure. When elitedesk-1/2/3 come online, enable `orbal.dnsResolver` on multiple stable hosts and list all of them as Split-DNS nameservers (Tailscale supports multiple).
