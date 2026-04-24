---
name: conventions
description: How code is written in this project — naming, structure, patterns, and style. Load when writing new code or reviewing existing code.
triggers:
  - "convention"
  - "pattern"
  - "naming"
  - "style"
  - "how should I"
  - "what's the right way"
  - "module"
edges:
  - target: context/architecture.md
    condition: when a convention depends on understanding the system structure
  - target: patterns/add-module.md
    condition: when authoring a new flake module
  - target: patterns/add-secret.md
    condition: when the change involves a sops-encrypted value
last_updated: 2026-04-24
---

# Conventions

## Naming
- Module files: kebab-case, one module per file in `modules/<name>.nix` (e.g. `tailnet-hosts.nix`, `dns-resolver.nix`).
- Module option namespace: `orbal.<module-name>.<option>` — always prefixed `orbal.` so the project's surface is distinct from upstream nixpkgs options.
- Every module exposes an `enable` toggle under its namespace (e.g. `orbal.reverse-proxy.enable`). No always-on modules.
- Host directories: lowercase single word or hyphenated (`forge`, `seed`, `elitedesk-1`).
- Secret keys inside sops YAML: snake_case, grouped by purpose (e.g. `tailscale_auth_key`, `dns_api_token`). [VERIFY AFTER FIRST IMPLEMENTATION]

## Structure
- Shared capabilities go in `modules/`, never inlined in `hosts/<host>/`. Host files only import and set option values.
- Secrets are declared in `modules/secrets.nix` (or the module that owns them) via `sops.secrets.<name>`; never read from raw paths.
- Overlays live in `overlays/default.nix` and are applied through the flake, not scattered per-host.
- Host-specific disk and hardware layout stays in `hosts/<host>/` (e.g. disko config, hardware-configuration.nix).
- Everything the flake needs to produce a host must be in the repo — if activation reads from outside the store, that's a bug.

## Patterns
Safety-first module authoring — a module must be safe to enable on any host and inert when disabled:

```nix
# Correct — gated on enable, defaults off
{ config, lib, ... }:
let cfg = config.orbal.reverse-proxy;
in {
  options.orbal.reverse-proxy.enable = lib.mkEnableOption "reverse proxy";
  config = lib.mkIf cfg.enable {
    services.nginx.enable = true;
    # ...
  };
}

# Wrong — side effects at top level
{ ... }: {
  services.nginx.enable = true;  # runs on every host that imports this
}
```

Secrets always go through sops-nix, never a raw file path:

```nix
# Correct
sops.secrets.tailscale_auth_key = { owner = "root"; };
services.tailscale.authKeyFile = config.sops.secrets.tailscale_auth_key.path;

# Wrong
services.tailscale.authKeyFile = "/run/keys/tailscale";  # bypasses sops-nix, unaudited
```

## Verify Checklist
Before presenting any code:
- [ ] `nix flake check` passes.
- [ ] For each affected host: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` succeeds.
- [ ] New modules expose an `orbal.<name>.enable` toggle and are inert when disabled.
- [ ] No plaintext secrets introduced; every sensitive value references `config.sops.secrets.<name>.path`.
- [ ] No imperative install or curl-piped script added; all new tools flow through nixpkgs or a flake input.
- [ ] Change is committed — no host will be deployed from an uncommitted tree (auditability).
