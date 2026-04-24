# Pattern Index

Lookup table for all pattern files in this directory. Check here before starting any task — if a pattern exists, follow it.

| Pattern | Use when |
|---------|----------|
| [add-module.md](add-module.md) | Authoring a new shared flake module under `modules/` |
| [add-secret.md](add-secret.md) | Adding or rotating a sops-encrypted secret |
| [wire-module-into-host.md](wire-module-into-host.md) | Enabling an existing module on a specific host |
| [runbooks/first-deploy.md](runbooks/first-deploy.md) | First deploy of a brand-new host — secrets enrollment, sops updatekeys, tailnet join |
| [runbooks/rebuild.md](runbooks/rebuild.md) | Rebuilding / deploying an existing host (remote or on-host `rebuild`) |
| [runbooks/new-host.md](runbooks/new-host.md) | Adding a new host entry to the flake |
| [runbooks/disaster-recovery.md](runbooks/disaster-recovery.md) | Recovering a host from a lost secret key, broken boot, or dead disk |
| [runbooks/forge-vm.md](runbooks/forge-vm.md) | Operating the `forge` dev VM on TrueNAS Scale |
| [runbooks/nixos-infect-hetzner.md](runbooks/nixos-infect-hetzner.md) | Converting an Ubuntu/Debian Hetzner VPS to NixOS via `nixos-infect` |
