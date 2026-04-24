# orbal

NixOS flake configuration and knowledgebase for the orbal homelab fleet.

## Hosts

| Host | Role | Status |
|------|------|--------|
| `orbal` | Main server — Plex, *arr suite | Active |
| `elitedesk-1` | Compute node | Planned |
| `elitedesk-2` | Compute node | Planned |
| `elitedesk-3` | Compute node | Planned |

## Quick start

```bash
# Build the orbal configuration
nix build .#nixosConfigurations.orbal.config.system.build.toplevel

# Deploy to orbal (from the repo)
nixos-rebuild switch --flake .#orbal --target-host orbal

# Check the flake
nix flake check
```

## Structure

```
hosts/       Per-host NixOS configurations
modules/     Shared, composable NixOS modules
overlays/    Package overlays
wiki/        Homelab knowledgebase
```

## Wiki

See [wiki/README.md](wiki/README.md) for the full knowledgebase index.
