# 003: `.orbal` Split-DNS for tailnet service URLs

## Date
2026-04-24

## Context

We want tailnet services to be reachable at stable, human-readable URLs of the shape `<service>.<host>`. The first candidate was `<service>.<host>.<tailnet>.ts.net` with HTTPS via Tailscale's built-in ACME — nice because Tailscale would handle certs and DNS for us.

That turned out not to work today:

- `tailscale cert` ([kb/1153](https://tailscale.com/kb/1153/enabling-https)) only issues certificates for a node's own MagicDNS name. No wildcards, no subdomains under `<host>.<tailnet>.ts.net`.
- MagicDNS ([kb/1081](https://tailscale.com/kb/1081/magicdns), [kb/1054](https://tailscale.com/kb/1054/dns)) returns NXDOMAIN for anything under a node name, and the admin console exposes no custom records under `*.ts.net`.

Alternatives considered:

1. **Path-based on `<host>.<tailnet>.ts.net`** — e.g. `https://forge.<tailnet>.ts.net/ollama/`. Simplest, gets Tailscale ACME certs for free. Rejected because path-based routing breaks some apps (Open WebUI among them) and doesn't read as naturally as subdomains.
2. **Per-service Tailscale nodes via `caddy-tailscale`** — each service becomes its own tailnet node with its own MagicDNS name. Rejected because it loses the `.host` grouping in the URL and grows the Tailscale node count linearly with service count.
3. **Real domain + DNS-01 ACME** (e.g. `*.forge.bask.health` or a throwaway domain) — would give proper HTTPS. Deferred; not wanted today because we don't want to tie homelab DNS to work DNS or buy another domain yet.

## Decision

Use a fake `.orbal` TLD, resolved by our own dnsmasq on seed, with Tailscale's admin-panel Split-DNS routing `*.orbal` queries there. Plain HTTP over the tailnet — no ACME, no cert management. The tailnet is already WireGuard-encrypted end-to-end, so HTTP inside the mesh is not an extra exposure.

Implementation: `modules/reverse-proxy.nix` (per-host Caddy), `modules/dns-resolver.nix` (dnsmasq, opt-in), `modules/tailnet-hosts.nix` (host → tailnet-IP map). One manual Tailscale admin step (documented in `wiki/services/reverse-proxy.md`).

## Rationale

- Zero cert management. Fake TLD means no public CA will ever issue for it, so ACME is off the table by construction — and we don't need it.
- Subdomain URLs (`<service>.<host>.orbal`) read naturally and compose well.
- dnsmasq's `address=/host.orbal/IP` matches the host and every subdomain, so the DNS config is one line per host regardless of how many services run there.
- The three-invariant tailnet-only pattern (bind-all + closed firewall + trusted tailscale0) carries over unchanged from `local-llm.nix`.

## Revisit when

- A browser-security corner of plain HTTP bites (e.g. Secure-cookie login breakage). Flip to `tls internal` first, real domain + ACME second.
- We want the services reachable from contexts where the tailnet is not available (the fake TLD stops resolving off-tailnet by design).
- We buy a real domain for the homelab; then moving to `<service>.<host>.<domain>` with real DNS-01 wildcards is a clean next step.
