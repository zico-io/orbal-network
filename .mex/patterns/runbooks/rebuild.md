# Rebuilding / Deploying

## Local rebuild (on the host itself)

The `rebuild` wrapper (defined in `modules/shell.nix`, installed when `orbal.shell.enable = true`) is the ergonomic path — it walks up from `$PWD` to find `flake.nix` (falling back to `~/orbal-network`) and defaults the target to the current host:

```bash
rebuild              # switch, current host
rebuild boot         # boot action, current host
rebuild switch seed  # override host
```

Equivalent raw form:

```bash
sudo nixos-rebuild switch --flake /path/to/orbal#<hostname>
```

## Remote deploy (from your workstation)

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --use-remote-sudo
```

Relies on `nix.settings.trusted-users = [ "root" "@wheel" ]` in `modules/base.nix` so wheel members can push unsigned store paths (host-specific derivations aren't in cache.nixos.org and aren't signed).

**First deploy onto a fresh host** (before that trust is baked in) — build on the target to skip the push entirely:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --build-host <hostname> --use-remote-sudo
```

Once the first switch lands, `--build-host` is optional.

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
