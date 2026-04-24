# Disaster Recovery

## What's declarative (safe)

Everything in this repo — NixOS configs, module definitions, service declarations. A fresh NixOS install + `nixos-rebuild switch --flake .#<host>` recreates the full system.

## What's stateful (back up)

| Data | Location | Backup method |
|------|----------|---------------|
| SSH host key (sops-age recipient) | `/etc/ssh/ssh_host_ed25519_key` | Off-host backup — without it, sops secrets can't be decrypted on a replacement host |
| User home directory (if any local state) | `/home/stperc` | Off-host backup or re-derivable from dotfiles in this repo |
| Podman volumes (if containers are added) | `podman volume ls` | `podman volume export <name>` |

Currently no host in this repo defines application state worth backing up beyond the SSH host key. Expand this table when stateful services (Plex, databases, etc.) are added.

## Full restore procedure

1. Install NixOS on replacement hardware
2. Either restore the SSH host key from backup or generate a new one and add its age recipient to `.sops.yaml`, then re-encrypt secrets with `sops updatekeys secrets/dev.yaml`
3. Clone this repo
4. Run `nixos-rebuild switch --flake .#<host>`
5. Restore any state backups (Podman volumes, home directory, etc.)

## Backup strategy (TBD)

No automated backups yet. Candidates when needed:

- SSH host keys → small, copy to password manager or off-site box
- Podman volumes → systemd timer invoking `podman volume export` + offsite sync
- Consider a dedicated `modules/backup.nix` once there's state to back up
