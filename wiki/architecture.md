# System Architecture

## Overview

The zebes homelab is a fleet of NixOS machines managed declaratively via a single flake.

**zebes** is the primary node — a headless server running the media stack (Plex + *arr suite) in Podman containers. All services are defined as NixOS modules and deployed with `nixos-rebuild switch --flake`.

Three **HP Elitedesk** mini-PCs currently run Proxmox. The long-term plan is bare-metal NixOS on all three, joining this flake as additional hosts.

## Network

Networking is handled by the Unifi stack (not managed by Nix). See [Network Topology](network-topology.md) for details.

## Secrets

Secrets (API keys, tokens) are managed with sops-nix. Encrypted files live in the repo under `secrets/`, decrypted at activation time using each host's SSH host key.

## Deployment

```
local machine → git push → (optional CI check) → nixos-rebuild switch --flake .#<host> --target-host <host>
```
