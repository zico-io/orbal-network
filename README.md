# zebes

NixOS flake configuration and knowledgebase for the zebes homelab fleet.

## Hosts

| Host | Role | Status |
|------|------|--------|
| `zebes` | Main server — Plex, *arr suite | Active |
| `elitedesk-1` | Compute node | Planned |
| `elitedesk-2` | Compute node | Planned |
| `elitedesk-3` | Compute node | Planned |

## Quick start

```bash
# Build the zebes configuration
nix build .#nixosConfigurations.zebes.config.system.build.toplevel

# Deploy to zebes (from the repo)
nixos-rebuild switch --flake .#zebes --target-host zebes

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
