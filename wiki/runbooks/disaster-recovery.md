# Disaster Recovery

## What's declarative (safe)

Everything in this repo — NixOS configs, module definitions, service declarations. A fresh NixOS install + `nixos-rebuild switch --flake .#<host>` recreates the full system.

## What's stateful (back up)

| Data | Location | Backup method |
|------|----------|---------------|
| Plex config + DB | `plex-config` volume | `podman volume export` |
| Sonarr config | `sonarr-config` volume | `podman volume export` |
| Radarr config | `radarr-config` volume | `podman volume export` |
| Prowlarr config | `prowlarr-config` volume | `podman volume export` |
| Media files | `/data/media` | External backup (TBD) |
| Downloads | `/data/downloads` | Not critical — re-downloadable |
| sops age keys | `/etc/ssh/ssh_host_ed25519_key` | Back up manually |

## Full restore procedure

1. Install NixOS on replacement hardware
2. Copy SSH host key (or generate new and update `.sops.yaml`)
3. Clone this repo
4. Run `nixos-rebuild switch --flake .#<host>`
5. Import Podman volumes:
   ```bash
   podman volume import plex-config plex-config-backup.tar
   podman volume import sonarr-config sonarr-config-backup.tar
   # etc.
   ```
6. Restart services: `sudo systemctl restart podman-*`

## Backup script (TBD)

Automate volume exports + offsite sync. Consider a NixOS module or systemd timer.
