---
name: stack
description: Technology stack, library choices, and the reasoning behind them. Load when working with specific technologies or making decisions about libraries and tools.
triggers:
  - "library"
  - "package"
  - "dependency"
  - "which tool"
  - "technology"
  - "nix"
  - "sops"
  - "flake"
edges:
  - target: context/decisions.md
    condition: when the reasoning behind a tech choice is needed
  - target: context/conventions.md
    condition: when understanding how to use a technology in this codebase
  - target: context/secrets.md
    condition: when working with sops-nix or encrypted values
  - target: context/architecture.md
    condition: when placing a library or runtime into the overall system flow
last_updated: 2026-04-24
---

# Stack

## Core Technologies
- **Nix / NixOS (release 25.05)** — flake-based; the language and the runtime for every host configuration.
- **sops + age (via sops-nix)** — secret encryption at rest, decrypted into runtime paths at activation.
- **home-manager (release-25.05)** — per-user environment management, consumed as a flake input.
- **disko** — declarative disk layout for hosts that provision from scratch.
- **TypeScript / Python / Rust** — secondary languages enabled via `modules/languages.nix` on dev hosts; not used for the infra layer itself.

## Key Libraries
- **sops-nix** (not manual age/ssh secret wiring) — every secret reference goes through `sops.secrets.<name>` so activation decrypts to the correct path with the correct owner/mode.
- **disko** (not hand-rolled partitioning) — disk layout is declared in `hosts/<host>/disko.nix` style configs.
- **claude-code-nix + agent-skills-nix + anthropic-skills** — agent tooling is managed as flake inputs, not curl-piped installs.
- **Tailscale module** (via nixpkgs + `modules/tailnet-hosts.nix`) — the tailnet wiring is a module, not ad-hoc config.

## What We Deliberately Do NOT Use
- No imperative provisioners (Ansible, Chef, Puppet, SaltStack) — Nix is the only configuration surface.
- No `curl | sh` or unpinned external installers — everything flows through flake inputs or nixpkgs.
- No plaintext `.env`, `.envrc` with secrets, or committed credentials — sops is the only path for sensitive values.
- No non-NixOS targets for infra (beyond what the flake produces) — portability is not a goal.

## Version Constraints
- nixpkgs is pinned to `nixos-25.05`; home-manager and sops-nix follow the same release line. Don't bump channels piecemeal — update the lockfile in one coordinated `nix flake update` and re-validate every host.
