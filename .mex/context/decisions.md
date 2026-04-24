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
**Decision:** All secrets live under `secrets/` as sops-encrypted YAML (`secrets/dev.yaml` today); modules reference values exclusively through `config.sops.secrets.<name>.path`.
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

### ADR-001: Podman over Docker
**Date:** 2026-04-20
**Status:** Active
**Decision:** Podman is the container runtime for the homelab media stack on NixOS.
**Reasoning:** NixOS's `virtualisation.oci-containers` module defaults to Podman and generates systemd services per container — ideal for a declarative, headless setup. Rootless by default (a container escape yields only unprivileged access). Daemonless — no persistent root daemon consuming memory; each container is a fork-exec process. Systemd-native — every container becomes a systemd unit with journald logging, restart policies, and dependency ordering for free. `dockerCompat` aliases the `docker` CLI to `podman`, so existing muscle memory works. OCI-compatible — same images, same registries.
**Alternatives considered:** Docker (rejected — rootful daemon, weaker NixOS integration, brings Portainer/Watchtower-class tools that duplicate what the Nix config already is).
**Consequences:** No need for Docker-specific management tools — the Nix config is the source of truth for container lifecycle.

### ADR-002: Multi-host flake structure (`hosts/`, `modules/`)
**Date:** 2026-04-20
**Status:** Active
**Decision:** Top-level layout is `hosts/<hostname>/` (per-machine config + hardware) and `modules/` (composable shared modules), with a `mkHost` helper in `flake.nix` that assembles every host.
**Reasoning:** `hosts/<hostname>/` keeps per-machine config isolated; each host has its own `default.nix` and `hardware.nix`. `modules/` holds composable, opt-in NixOS modules — not everything applies to every host. `mkHost` reduces per-host boilerplate: every host gets `base.nix` and `users.nix` automatically; additional modules are imported per-host. Adding a new host is: create a directory, add `hardware.nix` from the target, write a `default.nix` importing needed modules, and add one line to `flake.nix`.
**Alternatives considered:** Single flat config (rejected — doesn't scale past 1–2 hosts), separate flake per host (rejected — duplicates module definitions and drifts).
**Consequences:** Every new machine follows the same onboarding recipe (see `.mex/patterns/runbooks/new-host.md`). Shared knowledge lives in `.mex/` alongside the config so docs and system definition are versioned together.

### ADR-003: `.orbal` split-DNS for tailnet service URLs
**Date:** 2026-04-24
**Status:** Active
**Decision:** Tailnet services are reachable at `http://<service>.<host>.orbal` via a fake `.orbal` TLD resolved by dnsmasq on seed, with Tailscale admin-panel Split-DNS routing `*.orbal` queries there. Plain HTTP over the tailnet; no ACME, no cert management.
**Reasoning:** `tailscale cert` only issues certificates for a node's own MagicDNS name — no wildcards, no subdomains. MagicDNS returns NXDOMAIN for anything under a node name. Path-based routing on `<host>.<tailnet>.ts.net` breaks some apps (Open WebUI among them). The tailnet is already WireGuard-encrypted end-to-end, so plain HTTP inside the mesh is not an extra exposure. Fake TLD means no public CA will ever issue for it, so ACME is off the table by construction. Subdomain URLs (`<service>.<host>.orbal`) read naturally and compose well. dnsmasq's `address=/host.orbal/IP` matches the host and every subdomain, so DNS config is one line per host regardless of service count.
**Alternatives considered:** Path-based on `<host>.<tailnet>.ts.net` (rejected — breaks some apps, reads less naturally), per-service Tailscale nodes via `caddy-tailscale` (rejected — loses the `.host` grouping in the URL and grows Tailscale node count linearly with service count), real domain + DNS-01 ACME (deferred — no desire to tie homelab DNS to work DNS or buy another domain yet).
**Consequences:** Implementation lives in `modules/reverse-proxy.nix`, `modules/dns-resolver.nix`, `modules/tailnet-hosts.nix`. One manual Tailscale admin step (documented in `.mex/context/services/reverse-proxy.md`). Revisit when a browser-security corner of plain HTTP bites, when services need to be reachable off-tailnet, or when we buy a real domain for the homelab.
