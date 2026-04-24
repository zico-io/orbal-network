---
name: architecture
description: How the major pieces of this project connect and flow. Load when working on system design, integrations, or understanding how components interact.
triggers:
  - "architecture"
  - "system design"
  - "how does X connect to Y"
  - "integration"
  - "flow"
  - "module"
  - "host"
edges:
  - target: context/stack.md
    condition: when specific technology details are needed
  - target: context/decisions.md
    condition: when understanding why the architecture is structured this way
  - target: context/secrets.md
    condition: when the change touches sops-encrypted values or secret wiring
  - target: context/conventions.md
    condition: when moving from understanding structure to actually writing a module or host change
  - target: patterns/add-module.md
    condition: when introducing a new capability as a flake module
  - target: patterns/wire-module-into-host.md
    condition: when an existing module needs to be enabled on a host
last_updated: 2026-04-24
---

# Architecture

## System Overview
The flake is the single source of truth. Change flow for any system modification:

1. Author or edit a module under `modules/<name>.nix` exposing an `orbal.<name>.enable` toggle.
2. Wire it into one or more hosts under `hosts/<host>/` (default.nix imports + option values).
3. Encrypt any needed secrets into `secrets/*.yaml` via sops; reference them in the module via sops-nix.
4. Validate: `nix flake check` and `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
5. Deploy: `nixos-rebuild switch --flake .#<host> --target-host <host>` (or on-host `rebuild`).

Every host's runtime config is a pure function of the repo at HEAD — no imperative drift.

## Key Components
- **flake.nix** — inputs (nixpkgs 25.05, home-manager, sops-nix, disko, claude-code, agent-skills) and the `mkHost` helper that assembles every host from shared modules + per-host config.
- **hosts/** — one directory per machine (`forge`, `seed` active; `elitedesk-1..3` planned). Each holds the host-specific NixOS config and disko layout.
- **modules/** — shared, toggleable capabilities (`base`, `users`, `secrets`, `shell`, `tailnet-hosts`, `reverse-proxy`, `dns-resolver`, `agents`, `local-llm`, `containers`, `vm-guest`, …). Each gated by `orbal.<name>.enable`.
- **secrets/** — sops-age encrypted YAML (`dev.yaml` today). Decryption keys are per-host; wiring happens in `modules/secrets.nix`.
- **overlays/** — package overlays applied via flake overlays output.
- **skills/** — local agent skills materialised into `~/.claude/skills` on hosts that enable `orbal.agents.skills`.

## External Dependencies
- **Tailscale** — the tailnet. Hosts address each other over Tailscale; `modules/tailnet-hosts.nix` is the wiring. Auth keys are sops secrets.
- **sops + age** — secret encryption. Every secret file is committed encrypted; decryption keys are provisioned per host.
- **nixpkgs (release-25.05)** — pinned upstream via flake input; updates are deliberate `nix flake update` bumps.
- **Hetzner Robot / TrueNAS Scale / bare-metal** — host substrates for `seed`, `forge`, and the planned elitedesks respectively.

## What Does NOT Exist Here
- No imperative configuration tooling (Ansible, Chef, Puppet, bash provisioning scripts).
- No plaintext secrets — ever. If a value is sensitive, it goes through sops.
- No out-of-repo modifications to hosts — if it's not in the flake, it isn't part of the system.
- No application code that belongs to a product — this repo is infra/config only; application services live in their own repos and are consumed as packages or containers.
