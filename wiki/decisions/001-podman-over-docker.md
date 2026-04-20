# 001: Podman over Docker

## Date
2026-04-20

## Context
Need a container runtime for the homelab media stack on NixOS.

## Options considered

**Docker**: Industry standard, largest ecosystem, most tutorials assume it.

**Podman**: OCI-compatible, rootless by default, daemonless, systemd-native.

## Decision
Podman.

## Rationale
- NixOS's `virtualisation.oci-containers` module defaults to Podman and generates systemd services per container — ideal for a declarative, headless setup.
- Rootless by default. A container escape yields only unprivileged access.
- Daemonless — no persistent root daemon consuming memory. Each container is a fork-exec process.
- Systemd-native — every container becomes a systemd unit with journald logging, restart policies, and dependency ordering for free.
- `dockerCompat` aliases the `docker` CLI to `podman`, so existing muscle memory works.
- OCI-compatible — same images, same registries.
- No need for Docker-specific management tools (Portainer, Watchtower) since the Nix config is the source of truth.
