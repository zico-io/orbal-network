---
name: wire-module-into-host
description: Enable an existing flake module on a specific host by setting its orbal.<name>.* options under hosts/<host>/. Use whenever a host needs to turn on a capability.
triggers:
  - "enable on host"
  - "wire into host"
  - "turn on module"
  - "host config"
  - "opt in"
edges:
  - target: patterns/add-module.md
    condition: when the module does not yet exist and must be authored first
  - target: context/architecture.md
    condition: when unsure how the host config is assembled from shared modules
  - target: context/secrets.md
    condition: when enabling the module pulls in a new secret
last_updated: 2026-04-24
---

# Pattern: Wire a module into a host

## Context
Load `context/architecture.md` for the flake → mkHost → hosts/<host>/ flow. Skim the target host directory (`hosts/forge/` or `hosts/seed/`) to match its style. The module being enabled must already exist under `modules/`; if not, start with `patterns/add-module.md`.

## Steps
1. Open `hosts/<host>/default.nix` (or the appropriate sub-file in that host directory).
2. Set `orbal.<name>.enable = true;` and any required options (`orbal.<name>.domain`, `orbal.<name>.ports`, etc.).
3. If the module requires a secret that isn't yet encrypted for this host, follow `patterns/add-secret.md` first.
4. Dry build: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
5. Confirm the expected services show up in the output config: `nix eval .#nixosConfigurations.<host>.config.<path>`.
6. Deploy: `nixos-rebuild switch --flake .#<host> --target-host <host>`. For the current host, `rebuild` is fine.
7. Verify on the host: `systemctl status <service>`, `journalctl -u <service> -b`.

## Gotchas
- Enabling a module that opens ports without also configuring the firewall lands you with a service running but unreachable (or worse, reachable from the wrong interface). Check `networking.firewall` in the host or module.
- Modules with secrets will fail activation if the host's age key isn't a recipient in `.sops.yaml` for the needed file. Re-encrypt first, then deploy.
- Overlapping modules (two modules both enabling `services.nginx`) will merge silently or error depending on the options. Search existing hosts for the same service before enabling.
- Deploying from a dirty working tree breaks auditability — the activated toplevel won't match any commit. Commit first, then deploy.

## Verify
- [ ] `nix flake check` passes.
- [ ] `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` succeeds.
- [ ] The working tree is clean (or the change is committed) before deploy.
- [ ] Post-deploy: target service is active and reachable from where it should be, not from where it shouldn't.
- [ ] No secret was read from a hard-coded path; all references go through `config.sops.secrets.<name>.path`.

## Debug
- Activation fails with "file not found" on a secret → sops-nix couldn't decrypt, usually because the host's key isn't in the recipient list. Fix `.sops.yaml`, `sops updatekeys secrets/<file>.yaml`, redeploy.
- Service starts but does nothing useful → option wasn't what you thought. `nix eval .#nixosConfigurations.<host>.config.<option-path>` to inspect the resolved value.
- Host unreachable after deploy → you changed SSH or firewall config incorrectly. If console access exists, roll back to the previous generation (`nixos-rebuild --rollback` on the host). If not, you're in a recovery scenario — handle out of band.

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" if this changed what a host does.
- [ ] If a new cross-host dependency emerged (e.g. host A now expects host B to be up), note it in `context/architecture.md`.
