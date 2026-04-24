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

TBD — document local DNS setup.

## Ports

Listed ports are those actually exposed on at least one host today.

| Port | Service | Host |
|------|---------|------|
| 22 | SSH | forge, seed |

### Tailscale-only (opt-in)

Bound to `0.0.0.0`, reachable only via `tailscale0` (trusted interface in `modules/base.nix`). Public firewall stays closed.

| Port | Service | Module | Hosts |
|------|---------|--------|-------|
| 11434 | Ollama HTTP API (OpenAI-compatible `/v1`) | `orbal.local-llm` | forge |
| 8080 | Open WebUI chat front-end | `orbal.local-llm.webui` | forge |
