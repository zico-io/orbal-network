---
name: add-module
description: Author a new shared flake module under modules/ with an orbal.<name>.enable toggle. Use whenever introducing a new capability that any host may opt into.
triggers:
  - "new module"
  - "add module"
  - "add capability"
  - "create a module"
  - "orbal.*.enable"
edges:
  - target: context/conventions.md
    condition: when confirming naming, structure, and the safety-first authoring pattern
  - target: context/architecture.md
    condition: when the module touches cross-host concerns (tailnet, DNS, reverse proxy)
  - target: patterns/wire-module-into-host.md
    condition: after the module exists and needs to be enabled on a specific host
  - target: patterns/add-secret.md
    condition: when the new module consumes a sensitive value and needs a sops secret wired in
last_updated: 2026-04-24
---

# Pattern: Add a new flake module

## Context
Load `context/conventions.md` (module authoring pattern + verify checklist) and `context/architecture.md` (where modules sit in the flow). Glance at an existing module like `modules/reverse-proxy.nix` or `modules/dns-resolver.nix` as a shape reference. [VERIFY AFTER FIRST IMPLEMENTATION — swap in the canonical reference module once one is explicitly blessed.]

## Steps
1. Pick a kebab-case filename under `modules/` (one module per file) — e.g. `modules/<your-capability>.nix`.
2. Create the file with the standard shape:
   - `options.orbal.<name>.enable = lib.mkEnableOption "<human description>";`
   - Additional options under `options.orbal.<name>.*` as needed, each with a `type` and a `default`.
   - Everything that causes side effects goes inside `config = lib.mkIf cfg.enable { ... };`.
3. Register the module in `flake.nix` — add `./modules/<name>.nix` to the `mkHost` modules list so every host eval sees the option.
4. Leave the module disabled by default. Enabling happens per-host via `patterns/wire-module-into-host.md`.
5. If the module needs secrets, declare them via `sops.secrets.<name>` here (or wire through `modules/secrets.nix`) — do not hard-code paths.
6. Run `nix flake check`.
7. Build every active host to prove the module is inert when disabled:
   - `nix build .#nixosConfigurations.forge.config.system.build.toplevel`
   - `nix build .#nixosConfigurations.seed.config.system.build.toplevel`

## Gotchas
- Top-level side effects (anything outside `config = lib.mkIf cfg.enable`) will fire on every host that imports the module — even hosts that leave the toggle off. This has bitten us before; always gate.
- Forgetting to add the module to `flake.nix`'s `mkHost` list means the option is silently absent, and hosts that try to set it fail with a confusing "attribute does not exist" error.
- Using a name that collides with an upstream nixpkgs module namespace causes silent option merges. Stay under `orbal.*`.
- Referencing secrets by raw `/run/secrets/...` paths bypasses sops-nix ownership/mode handling. Always use `config.sops.secrets.<name>.path`.

## Verify
- [ ] Module file is `modules/<kebab-name>.nix` with a single top-level attrset.
- [ ] `options.orbal.<name>.enable` exists and defaults to `false`.
- [ ] All side effects are inside `lib.mkIf cfg.enable`.
- [ ] Module is listed in `flake.nix` `mkHost` modules.
- [ ] `nix flake check` passes.
- [ ] Every active host still builds with the new module present but disabled.
- [ ] No plaintext secrets; any secret references use `config.sops.secrets.<name>.path`.

## Debug
- `nix flake check` fails with eval error → read the trace; 90% of the time it's a type mismatch in `options.<name>.type` or an unguarded side effect.
- Host build error "option does not exist" → module not registered in `flake.nix`.
- Host build error "multiple definitions" for a service you didn't set → another module is enabling the same service. Search `modules/` for the service name; either feature-flag coordinate or consolidate.

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" → add the new module to the Working list.
- [ ] If the module introduces a new domain (auth, observability, storage, etc.) with real depth, consider a `context/<domain>.md` file.
- [ ] If this pattern's Gotchas grew during this task, update the list.
