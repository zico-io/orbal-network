---
name: secrets
description: How secrets flow through this project — sops encryption, sops-nix wiring, per-host decryption. Load whenever a change touches sensitive values.
triggers:
  - "secret"
  - "sops"
  - "age"
  - "password"
  - "token"
  - "api key"
  - "credential"
edges:
  - target: context/architecture.md
    condition: when understanding how secrets fit into the overall flow
  - target: context/conventions.md
    condition: when checking the secret-wiring pattern and verify checklist
  - target: patterns/add-secret.md
    condition: when adding or rotating a sops-encrypted value
last_updated: 2026-04-24
---

# Secrets

## The Rule
Every sensitive value in this repo is sops-encrypted at rest. Plaintext secrets never land on disk, never appear in Nix source, never get printed by shell or module code.

## Where Secrets Live
- `secrets/dev.yaml` — the current sops-encrypted YAML store; additional files under `secrets/` will be added to split by scope/environment if/when that grows. [VERIFY AFTER FIRST IMPLEMENTATION — confirm split strategy once a second file is needed]
- `.sops.yaml` — creation rules: which recipients (age public keys) can decrypt which files. Every commit that adds a secret must keep this consistent.
- `modules/secrets.nix` — the wiring layer. New secrets are declared here as `sops.secrets.<name> = { ... }` with the correct owner/group/mode.

## How a Secret Gets Used
1. Edit with `sops secrets/<file>.yaml` — decrypts, opens `$EDITOR`, re-encrypts on save with the recipients from `.sops.yaml`.
2. Declare the secret in the owning module: `sops.secrets.<name> = { owner = "<service-user>"; mode = "0400"; };`.
3. Reference the activation-time path: `config.sops.secrets.<name>.path`. Never hard-code `/run/secrets/<name>` — use the accessor.
4. At host activation, sops-nix decrypts the file using the host's age key and materialises it at the referenced path with the requested ownership.

## Per-Host Decryption Keys
Each host has its own age key (derived from its SSH host key, typically). A secret can only be decrypted on a host whose public key is listed in `.sops.yaml` for that file's path. Rotating a host key requires re-encrypting every file that host needs.

## Non-Negotiables (secret-specific)
- Never `echo`, `printf`, or `${VAR:-fallback}` a secret variable — presence-checks leak the value. If you need to check presence, test the file path or use `[ -n "${VAR+x}" ]`.
- Never copy a decrypted secret out of `/run/secrets` into a checked-in path or a module string.
- Never commit a file that sops would have encrypted — run `git diff --cached` mentally for any YAML under `secrets/` before committing.
- Never add a new recipient without understanding the blast radius: that key can now decrypt everything it's listed for, forever (until re-encrypted after removal).

## What Lives Here vs Elsewhere
- This repo: infra-level secrets used by NixOS services (Tailscale auth keys, DNS API tokens, reverse-proxy certs-not-from-ACME, etc.).
- NOT this repo: per-user application secrets, one-off API keys for ad-hoc scripts, CI runner tokens (those belong to whatever service owns them).

## Open Questions
- [TO BE DETERMINED — populate after first implementation] How keys are distributed for a new human contributor (personal age key onboarding flow).
- [TO BE DETERMINED — populate after first implementation] Scope-splitting of secret files (one per env? one per host? one per capability?) once `dev.yaml` gets crowded.
