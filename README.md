# orbal

NixOS flake configuration and knowledgebase for the orbal homelab fleet.

## Hosts

| Host | Role | Status |
|------|------|--------|
| `forge` | Dev VM on TrueNAS Scale (mother-brain) | Active |
| `seed` | Hetzner Robot dedicated server (2× NVMe RAID1) | Active |
| `elitedesk-1` | Bare-metal compute node | Planned |
| `elitedesk-2` | Bare-metal compute node | Planned |
| `elitedesk-3` | Bare-metal compute node | Planned |

## Quick start

```bash
# Build a host configuration without activating
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Deploy to a host from the repo
nixos-rebuild switch --flake .#<host> --target-host <host>

# Check the flake
nix flake check
```

On a host itself, the `rebuild` wrapper (from `modules/shell.nix`) is shorter:

```bash
rebuild              # switch, current host
rebuild boot         # boot action, current host
rebuild switch seed  # override host
```

## Structure

```
hosts/       Per-host NixOS configurations (forge, seed)
modules/     Shared modules, each gated by its own orbal.<x>.enable toggle
overlays/    Package overlays
secrets/     sops-age encrypted secrets
skills/      Local agent skills synced into ~/.claude/skills via orbal.claude.agentSkills
wiki/        Homelab knowledgebase
```

## Wiki

See [wiki/README.md](wiki/README.md) for the full knowledgebase index.
