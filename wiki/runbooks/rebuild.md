# Rebuilding / Deploying

## Local rebuild (on the host itself)

```bash
sudo nixos-rebuild switch --flake /path/to/zebes#<hostname>
```

## Remote deploy (from your workstation)

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --use-remote-sudo
```

## Test before switching

```bash
# Build without activating
nixos-rebuild build --flake .#<hostname>

# Boot into the new config on next reboot (safe rollback)
nixos-rebuild boot --flake .#<hostname>
```

## Rollback

NixOS keeps previous generations. To roll back:

```bash
# List generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Roll back to previous
sudo nixos-rebuild switch --rollback
```

Or select a previous generation from the systemd-boot menu at boot time.

## Updating inputs

```bash
# Update all flake inputs
nix flake update

# Update a single input
nix flake update nixpkgs
```
