---
name: setup
description: Dev environment setup and commands. Load when setting up the project for the first time or when environment issues arise.
triggers:
  - "setup"
  - "install"
  - "environment"
  - "getting started"
  - "how do I run"
  - "local development"
  - "deploy"
edges:
  - target: context/stack.md
    condition: when specific technology versions or library details are needed
  - target: context/architecture.md
    condition: when understanding how components connect during setup
  - target: context/secrets.md
    condition: when the task involves decrypting or adding secrets
last_updated: 2026-04-24
---

# Setup

## Prerequisites
- Nix with flakes enabled (`experimental-features = nix-command flakes`).
- `sops` and an `age` key authorised for this repo (see `.sops.yaml` recipients). [VERIFY AFTER FIRST IMPLEMENTATION — confirm the key-provisioning workflow once a second contributor onboards]
- SSH access to any host you intend to deploy to, with root (or sudo-NOPASSWD) on the target.
- `nixos-rebuild` available locally (any NixOS or nix-on-linux machine with the binary on PATH).

## First-time Setup
1. Clone: `git clone <repo>` and `cd orbal-network`.
2. Install your age key and update `.sops.yaml` if you need access to encrypted files. [VERIFY AFTER FIRST IMPLEMENTATION]
3. Validate: `nix flake check`.
4. Build a host without activating: `nix build .#nixosConfigurations.forge.config.system.build.toplevel`.
5. Deploy (when ready): `nixos-rebuild switch --flake .#<host> --target-host <host>`.

## Environment Variables
This repo has no runtime env vars — configuration is fully declarative. Secret material is supplied through sops-nix at activation, not via shell env.

## Common Commands
- `nix flake check` — typecheck / eval all outputs; run this before every commit that touches Nix.
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` — dry build a host.
- `nixos-rebuild switch --flake .#<host> --target-host <host>` — deploy from the local checkout to a remote host.
- `rebuild` (on-host) — wrapper from `modules/shell.nix`; `rebuild boot`, `rebuild switch <host>` variants available.
- `sops` `secrets/dev.yaml` — edit an encrypted secret file (decrypt → $EDITOR → re-encrypt).
- `nix flake update` — bump all flake inputs; follow with `nix flake check` and a full host build sweep.

## Common Issues
- **`nix flake check` fails after a `flake update`:** a pinned input moved in a breaking way. Check the lockfile diff, revert the offending input, open a tracking issue.
- **`sops` cannot decrypt a file:** your age key isn't listed in `.sops.yaml` recipients for that path, or your key isn't on the machine. Fix the recipient list (then re-encrypt) or install your key.
- **Remote deploy hangs on activation:** usually a service that failed to start. SSH in, `journalctl -u <service> -b` to see the failure.
- **Secret owned by the wrong user after activation:** the module didn't set `sops.secrets.<name>.owner`; update the module, rebuild.
