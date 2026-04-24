# HP Elitedesk Mini-PCs

## Fleet

3x HP Elitedesk mini-PCs. Currently running Proxmox, planned migration to bare-metal NixOS.

## Specs

| Component | Detail |
|-----------|--------|
| Model | TBD |
| CPU | TBD |
| RAM | TBD |
| Storage | TBD |
| NIC | TBD |

## Migration Plan

1. Back up existing Proxmox VMs
2. Install NixOS via USB
3. Run `nixos-generate-config` and copy hardware config to repo
4. Add host to `flake.nix`
5. Deploy with `nixos-rebuild switch --flake .#elitedesk-N`

See [runbooks/new-host.md](../runbooks/new-host.md) for the full procedure.
