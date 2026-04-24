# First Deploy

Generic runbook for deploying any orbal host from a fresh NixOS install. For
host-specific runbooks see [forge-vm](./forge-vm.md) (TrueNAS VM) and
[nixos-infect-hetzner](./nixos-infect-hetzner.md) (Hetzner VPS/dedicated).

## Prerequisites

- NixOS installed on the target host with a working network connection
- SSH access from your workstation
- This repo cloned on your workstation

## 1. Generate hardware config

On the target:

```bash
nixos-generate-config --show-hardware-config
```

Save the output into `hosts/<hostname>/hardware.nix` in this repo.

## 2. Add your SSH public key

Confirm the `stperc` key in `modules/users.nix` matches the key you'll SSH with. Add additional keys there if onboarding another person.

## 3. Create the host entry

Follow [Adding a New Host](./new-host.md):

- `hosts/<hostname>/default.nix` imports `hardware.nix` and sets the bootloader (`systemd-boot` for EFI, `grub` for Hetzner BIOS).
- Opt into modules with `orbal.*.enable` toggles. A dev host uses `orbal.dev.enable = true` plus any `orbal.languages.*` / `orbal.agents.*` you want.
- Register the host in `flake.nix`: `<hostname> = mkHost "<hostname>";`.

## 4. Set up sops-nix (optional)

Needed only if the host uses `orbal.secrets.enable = true` (implicit when `orbal.dev.enable = true`).

On the target, derive an age recipient from the SSH host key:

```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

Add the key to `.sops.yaml` under `creation_rules`, then re-encrypt secrets:

```bash
nix-shell -p sops --run 'sops updatekeys secrets/dev.yaml'
```

## 5. Build and deploy

From your workstation:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --use-remote-sudo
```

Or on the target directly:

```bash
cd /path/to/orbal-network
sudo nixos-rebuild switch --flake .#<hostname>
```

The first build takes a while — nixpkgs and any pinned inputs (home-manager, agent-skills, …) are downloaded. Subsequent rebuilds only rebuild changed derivations.

## 6. Verify

```bash
# SSH still works (key auth, no password)
ssh <hostname>

# rebuild wrapper resolves correctly on the host
ssh <hostname> which rebuild

# Tailscale came up (if enabled in base.nix)
ssh <hostname> tailscale status
```

## 7. Commit

```bash
git add hosts/<hostname>/ flake.nix flake.lock
git commit -m "add <hostname> host"
```

## Troubleshooting

**Can't SSH after rebuild.** Check that your public key is in `modules/users.nix` and that `PasswordAuthentication` is only set to `false` after key-based auth is confirmed.

**Rebuild fails on sops activation.** The host's SSH host key must be in `.sops.yaml` and `secrets/*.yaml` must be re-encrypted against it. See step 4.

**Rollback a bad generation.**

```bash
ssh <hostname> sudo nixos-rebuild switch --rollback
```

Or pick a previous generation from the systemd-boot menu at boot.
