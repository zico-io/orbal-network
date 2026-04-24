---
name: decisions
description: Key architectural and technical decisions with reasoning. Load when making design choices or understanding why something is built a certain way.
triggers:
  - "why do we"
  - "why is it"
  - "decision"
  - "alternative"
  - "we chose"
edges:
  - target: context/architecture.md
    condition: when a decision relates to system structure
  - target: context/stack.md
    condition: when a decision relates to technology choice
  - target: context/secrets.md
    condition: when the decision concerns secret management
last_updated: 2026-04-24
---

# Decisions

<!-- HOW TO USE THIS FILE:
     Each decision follows the format below.
     When a decision changes: DO NOT delete the old entry.
     Mark it as superseded, add the new entry above it.
     The history must be preserved — this is the event clock. -->

## Decision Log

### Nix flake as the single configuration surface
**Date:** 2026-04-24
**Status:** Active
**Decision:** Every host in the orbal fleet is built from this flake; no imperative provisioning or out-of-repo configuration is allowed.
**Reasoning:** Reproducibility and auditability — any host state can be regenerated from HEAD, and every change is visible in git.
**Alternatives considered:** Ansible / Chef / Puppet (rejected — imperative, drifts, harder to audit), hand-rolled bash (rejected — unreviewable), NixOps (rejected — stale tooling, flakes cover the use case).
**Consequences:** Every new capability must be expressed as a Nix module. Agents must resist suggesting ad-hoc scripts.

### sops-nix for all secrets
**Date:** 2026-04-24
**Status:** Active
**Decision:** All secrets live in `secrets/*.yaml`, sops-encrypted; modules reference values exclusively through `config.sops.secrets.<name>.path`.
**Reasoning:** Encrypted-at-rest, per-host decryption keys, and first-class NixOS integration. Keeps the "never leak secrets" non-negotiable enforceable.
**Alternatives considered:** agenix (rejected — sops-nix has wider YAML/structured-secret support), Vault (rejected — adds a runtime dependency and operational surface for a small fleet), plaintext + .gitignore (rejected — one slip leaks the repo).
**Consequences:** Every new secret requires a sops edit and a module wiring step. See `patterns/add-secret.md`.

### Toggleable modules under the `orbal.*` namespace
**Date:** 2026-04-24
**Status:** Active
**Decision:** Every shared module exposes an `orbal.<name>.enable` option and is inert when disabled; hosts opt in explicitly.
**Reasoning:** Modularity and safety — importing a module must never cause side effects on a host that doesn't want it.
**Alternatives considered:** Always-on modules (rejected — couples all hosts to every capability), per-host copy-paste (rejected — drift and duplication).
**Consequences:** Authors must wrap module config in `lib.mkIf cfg.enable`. Reviewers should reject top-level side effects.

### Pin nixpkgs to a release channel, update deliberately
**Date:** 2026-04-24
**Status:** Active
**Decision:** `nixpkgs` is pinned to `nixos-25.05`; `home-manager` and `sops-nix` follow the same line. Updates are coordinated `nix flake update` bumps, not drive-by changes.
**Reasoning:** Prevents silent churn across hosts; every host runs against a known-good snapshot until we choose to move.
**Alternatives considered:** `nixos-unstable` (rejected — production fleet, we trade freshness for stability), per-host pins (rejected — fleet divergence is a bigger problem than occasional lag).
**Consequences:** When bumping, re-validate every host build before any deploy.
