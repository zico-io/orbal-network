# *arr Suite

## Overview

The *arr stack runs as Podman containers on zebes, managed by the `media-stack` NixOS module.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Sonarr | 8989 | TV show management |
| Radarr | 7878 | Movie management |
| Prowlarr | 9696 | Indexer management |

## Directory Layout

```
/data/
├── media/
│   ├── tv/          # Sonarr library
│   └── movies/      # Radarr library
└── downloads/       # Shared download directory
```

## Adding Services

To add more *arr apps (Bazarr, Overseerr, Lidarr, etc.), add a new container block in `modules/media-stack.nix` following the existing pattern.

## Backup

Each service stores its config in a named Podman volume:

```bash
for vol in sonarr-config radarr-config prowlarr-config; do
  podman volume export "$vol" > "${vol}-backup.tar"
done
```
