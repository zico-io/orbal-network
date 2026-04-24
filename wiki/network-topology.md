# Network Topology

## Overview

All networking is managed by the Unifi stack. NixOS hosts are consumers, not controllers.

## Hosts

| Host | IP | Role |
|------|-----|------|
| forge | 192.168.12.205 | Dev VM on TrueNAS (mother-brain) |
| seed | 46.62.190.233 | Hetzner dedicated server |
| elitedesk-1 | TBD | Compute node |
| elitedesk-2 | TBD | Compute node |
| elitedesk-3 | TBD | Compute node |

## VLANs

TBD — document VLAN layout as configured in Unifi.

## DNS

Two layers:

- **MagicDNS** (Tailscale) resolves node names (`forge`, `seed`) to tailnet IPv4s. Always on.
- **`.orbal` fake TLD** — dnsmasq on seed answers every `*.orbal` query with the matching host's tailnet IP. Tailscale admin → DNS → Split-DNS routes `.orbal` queries there. Tailnet clients can then reach services at `http://<service>.<host>.orbal`. See [Reverse proxy](services/reverse-proxy.md) and [ADR 003](decisions/003-orbal-split-dns.md).

The host → tailnet-IP map lives in `modules/tailnet-hosts.nix` (`orbal.tailnetHosts`).

## Ports

Listed ports are those actually exposed on at least one host today.

| Port | Service | Host |
|------|---------|------|
| 22 | SSH | forge, seed |

### Tailscale-only (opt-in)

Bound to `0.0.0.0` (or to `tailscale0` directly for dnsmasq), reachable only via `tailscale0` (trusted interface in `modules/base.nix`). Public firewall stays closed.

| Port | Service | Module | Hosts |
|------|---------|--------|-------|
| 53 (udp/tcp) | dnsmasq (`.orbal` resolver) | `orbal.dnsResolver` | seed |
| 80 | Caddy reverse proxy (`<service>.<host>.orbal`) | `orbal.reverseProxy` | forge |
| 11434 | Ollama HTTP API (OpenAI-compatible `/v1`) | `orbal.local-llm` | forge |
| 8080 | Open WebUI chat front-end | `orbal.local-llm.webui` | forge |
