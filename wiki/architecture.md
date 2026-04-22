# System Architecture

## Overview

The zebes homelab is a fleet of NixOS machines managed declaratively via a single flake.

**forge** is a dev VM running on TrueNAS Scale (mother-brain). **seed** is a Hetzner Robot dedicated server (2x NVMe RAID1). Both are managed as NixOS configurations in this flake.

Three **HP Elitedesk** mini-PCs currently run Proxmox. The long-term plan is bare-metal NixOS on all three, joining this flake as additional hosts.

## Network

Networking is handled by the Unifi stack (not managed by Nix). Tailscale is enabled fleet-wide for mesh connectivity. See [Network Topology](network-topology.md) for details.

## Secrets

Secrets (API keys, tokens) are managed with sops-nix. Encrypted files live in the repo under `secrets/`, decrypted at activation time using each host's SSH host key.

## Deployment

```
local machine → git push → (optional CI check) → nixos-rebuild switch --flake .#<host> --target-host <host>
```
