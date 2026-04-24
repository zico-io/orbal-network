---
name: agents
description: Always-loaded project anchor. Read this first. Contains project identity, non-negotiables, commands, and pointer to ROUTER.md for full context.
last_updated: 2026-04-24
---

# orbal

## What This Is
Declarative NixOS configurations for the orbal tailnet fleet — one flake, many hosts, sops-encrypted secrets.

## Non-Negotiables
- Never leak secrets — all secrets live in `secrets/*.yaml`, sops-encrypted; never commit plaintext, never print secret values from shell or Nix.
- Never break production hosts — validate every change with `nix flake check` and a dry build before deploy; deploys to live hosts require explicit confirmation.
- Every system change must be auditable — changes land in this repo via commits; no ad-hoc, out-of-band modifications to hosts.

## Commands
- Check flake: `nix flake check`
- Build host (no activate): `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Deploy remotely: `nixos-rebuild switch --flake .#<host> --target-host <host>`
- On-host rebuild: `rebuild` (switch current host), `rebuild boot`, `rebuild switch <host>`

## Scaffold Growth
After every task: if no pattern exists for the task type you just completed, create one. If a pattern or context file is now out of date, update it. The scaffold grows from real work, not just setup. See the GROW step in `ROUTER.md` for details.

## Navigation
At the start of every session, read `ROUTER.md` before doing anything else.
For full project context, patterns, and task guidance — everything is there.
