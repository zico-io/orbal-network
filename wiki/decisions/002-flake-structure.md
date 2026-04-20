# 002: Flake Structure

## Date
2026-04-20

## Context
Setting up a NixOS flake repo for a growing homelab fleet (1 server now, 3 more nodes planned).

## Decision
Multi-host flake with `hosts/`, `modules/`, and `wiki/` at the top level.

## Rationale
- `hosts/<hostname>/` keeps per-machine config isolated. Each host has its own `default.nix` and `hardware.nix`.
- `modules/` holds composable, shared NixOS modules. Hosts opt into modules via imports — not everything applies to every host.
- A `mkHost` helper in `flake.nix` reduces per-host boilerplate. Every host gets `base.nix` and `users.nix` automatically; additional modules are imported per-host.
- Adding a new host is: create a directory, add `hardware.nix` from the target, write a `default.nix` importing the modules it needs, and add one line to `flake.nix`.
- `wiki/` lives alongside the config so the knowledge and the system definition are versioned together.
