# Plex

## Overview

Plex runs as a Podman container on zebes using the `lscr.io/linuxserver/plex` image.

## Configuration

- **Host networking** enabled for DLNA discovery
- **Media path**: `/data/media` on host, mounted as `/media` in container
- **Config volume**: `plex-config` (named Podman volume)
- **Transcoding**: TBD — document GPU passthrough if applicable

## Claim Token

On first run, set the `PLEX_CLAIM` environment variable to link the server to your Plex account. Get a token at https://plex.tv/claim.

Once claimed, the token is no longer needed and can be removed.

## Backup

```bash
podman volume export plex-config > plex-config-backup.tar
```
