# First Deploy

Step-by-step guide to deploying orbal from a fresh NixOS install to a fully running homelab server.

## Prerequisites

- NixOS installed on orbal with a working network connection
- SSH access to orbal from your workstation
- This repo cloned on your workstation

## 1. Generate hardware config

On orbal:

```bash
nixos-generate-config --show-hardware-config
```

Copy the output and replace the contents of `hosts/orbal/hardware.nix` in this repo. This captures your disk layout, kernel modules, and hardware-specific settings.

## 2. Add your SSH public key

Edit `modules/users.nix` and add your public key:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key-here"
];
```

If you don't have an ed25519 key yet:

```bash
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
```

## 3. Set up sops-nix (optional, can defer)

On orbal, derive an age key from the SSH host key:

```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

Paste the output into `.sops.yaml` in place of the placeholder key. Then create your secrets file:

```bash
nix-shell -p sops --run 'sops secrets/orbal.yaml'
```

Skip this step if you don't have secrets to manage yet — the flake works without it.

## 4. Generate the lock file

On any machine with nix installed:

```bash
cd /path/to/orbal
nix flake update
```

This creates `flake.lock`, pinning all inputs to specific revisions. Commit it.

## 5. Create data directories

On orbal, create the media and download directories:

```bash
sudo mkdir -p /data/media/tv /data/media/movies /data/downloads
sudo chown -R 1000:1000 /data
```

The UID/GID 1000 matches the `PUID`/`PGID` set in the container configs.

## 6. Build and deploy

From your workstation:

```bash
nixos-rebuild switch --flake .#orbal --target-host orbal --use-remote-sudo
```

Or directly on orbal:

```bash
cd /path/to/orbal
sudo nixos-rebuild switch --flake .#orbal
```

The first build takes a while — it downloads nixpkgs and all container images. Subsequent rebuilds are fast (only changed derivations are rebuilt).

## 7. Verify services

After the rebuild completes:

```bash
# Check that Podman containers are running
ssh orbal podman ps

# Check systemd service status
ssh orbal systemctl status podman-plex podman-sonarr podman-radarr podman-prowlarr
```

You should see all four containers running. Access the web UIs:

| Service | URL |
|---------|-----|
| Plex | `http://orbal:32400/web` |
| Sonarr | `http://orbal:8989` |
| Radarr | `http://orbal:7878` |
| Prowlarr | `http://orbal:9696` |

## 8. Claim Plex server

On first launch, Plex needs to be claimed. The easiest method:

1. SSH tunnel to orbal: `ssh -L 32400:localhost:32400 orbal`
2. Open `http://localhost:32400/web` in your browser
3. Sign in with your Plex account and claim the server

## 9. Configure the *arr suite

1. **Prowlarr first** — add your indexers
2. **Sonarr** — add Prowlarr as an indexer, set root folder to `/tv`, add a download client
3. **Radarr** — add Prowlarr as an indexer, set root folder to `/movies`, add a download client

Each app stores its config in a named Podman volume, so these settings persist across rebuilds.

## 10. Commit and push

Once everything is working:

```bash
git add -A
git commit -m "configure orbal for first deploy"
git push
```

Your homelab is now declarative. Any future changes go through the repo.

## Troubleshooting

**Container won't start:**
```bash
ssh orbal journalctl -u podman-plex -n 50
```

**Can't SSH after rebuild:**
Check that your public key is in `modules/users.nix` and that `PasswordAuthentication` is `false` only after you've confirmed key-based auth works.

**Firewall blocking services:**
Verify ports are open:
```bash
ssh orbal sudo nft list ruleset | grep 32400
```

**Rollback if something breaks:**
```bash
ssh orbal sudo nixos-rebuild switch --rollback
```
Or select a previous generation from the systemd-boot menu at boot.
