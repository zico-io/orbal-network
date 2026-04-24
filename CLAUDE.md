---
name: agents
description: Always-loaded project anchor. Read this first. Contains project identity, non-negotiables, commands, and pointer to ROUTER.md for full context.
last_updated: 2026-04-24
---

# orbal

## What This Is
Declarative NixOS configurations for the orbal tailnet fleet — one flake, many hosts, sops-encrypted secrets.

## Non-Negotiables
- Never leak secrets — all secrets live under `secrets/` as sops-encrypted YAML (`secrets/dev.yaml` today); never commit plaintext, never print secret values from shell or Nix.
- Never break production hosts — validate every change with `nix flake check` and a dry build before deploy; deploys to live hosts require explicit confirmation.
- Every system change must be auditable — changes land in this repo via commits; no ad-hoc, out-of-band modifications to hosts.

## Commands
- Check flake: `nix flake check`
- Build host (no activate): `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Deploy remotely: `nixos-rebuild switch --flake .#<host> --target-host <host>`
- On-host rebuild: `rebuild` (switch current host), `rebuild boot`, `rebuild switch <host>`

## After Every Task
After completing any task: update `.mex/ROUTER.md` project state and any `.mex/` files that are now out of date. If no pattern existed for the task you just completed, create one in `.mex/patterns/`.

## Navigation
At the start of every session, read `.mex/ROUTER.md` before doing anything else.
For full project context, patterns, and task guidance — everything is there.
