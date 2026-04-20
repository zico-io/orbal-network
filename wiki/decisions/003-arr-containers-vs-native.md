# 003: *arr Suite as Containers vs Native NixOS Services

## Date
2026-04-20

## Context
Plex, Sonarr, Radarr, and Prowlarr need to run on zebes. NixOS has native service modules for some of these, and all have official container images.

## Decision
Run as OCI containers via `virtualisation.oci-containers`, not as native NixOS services.

## Rationale
- The linuxserver.io container images are well-maintained with fast update cadence. NixOS native modules for these apps lag behind upstream releases.
- Containers isolate application state in named Podman volumes. Backup is trivial: `podman volume export`. Restore is equally simple.
- Plex specifically benefits from containers — the linuxserver.io image bundles transcoding libraries and codec packs that are painful to manage natively.
- The NixOS `oci-containers` module generates a systemd service per container, so we still get declarative management, journald logging, and restart policies.
- Adding a new *arr app is just adding another container block to `modules/media-stack.nix`.
