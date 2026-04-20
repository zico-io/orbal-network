# Podman

## Overview

Podman is the container runtime for the zebes fleet. Configured in `modules/containers.nix`.

## Why Podman

See [decisions/001-podman-over-docker.md](../decisions/001-podman-over-docker.md).

## Useful Commands

```bash
# List running containers
podman ps

# View logs for a container
podman logs -f sonarr

# Pull latest images
podman auto-update --dry-run

# Manually trigger auto-update
sudo systemctl start podman-auto-update

# Export a volume for backup
podman volume export <volume-name> > backup.tar

# Import a volume from backup
podman volume import <volume-name> backup.tar

# Inspect container details
podman inspect <container-name>
```

## Auto-Updates

A systemd timer runs `podman auto-update` weekly (Sunday 03:00). Containers with the `io.containers.autoupdate=registry` label are automatically updated.

## Docker Compatibility

`dockerCompat` is enabled — the `docker` CLI command is aliased to `podman`. Existing muscle memory and scripts work as-is.
