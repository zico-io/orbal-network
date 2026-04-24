---
name: add-secret
description: Add or rotate a sops-encrypted secret and wire it into a module via sops-nix. Use whenever a new sensitive value enters the repo or an existing one needs rotation.
triggers:
  - "add secret"
  - "new secret"
  - "rotate secret"
  - "sops"
  - "encrypt"
  - "api key"
  - "token"
edges:
  - target: context/secrets.md
    condition: for the full model of how secrets flow end-to-end
  - target: context/conventions.md
    condition: when confirming the sops-nix wiring pattern and verify checklist
  - target: patterns/wire-module-into-host.md
    condition: after the secret is added and a host needs to be rebuilt to consume it
last_updated: 2026-04-24
---

# Pattern: Add or rotate a sops secret

## Context
Load `context/secrets.md` before anything. The secret flow is: encrypt in a file under `secrets/` (today that's `secrets/dev.yaml`) → declare in a module via `sops.secrets.<name>` → reference the runtime path. Skip any step and you either leak or you build a broken host.

## Steps
1. Confirm `.sops.yaml` recipients cover every host that must read this secret. If not, add the host's age public key to the relevant path rule.
2. Edit the encrypted file — run `sops` against `secrets/dev.yaml` (or the appropriate file). Add the key under a sensible group; use snake_case names. [VERIFY AFTER FIRST IMPLEMENTATION — confirm naming/grouping scheme once the second file is created.]
3. If you added a new recipient in step 1, re-encrypt existing files so the new key works: `sops updatekeys secrets/<file>.yaml`.
4. Declare the secret in the owning module (or `modules/secrets.nix` if it's cross-cutting):
   ```nix
   sops.secrets.<name> = {
     owner = "<service-user>";
     group = "<service-group>";
     mode  = "0400";
   };
   ```
5. Reference the decrypted path in the consuming option:
   ```nix
   services.<thing>.authKeyFile = config.sops.secrets.<name>.path;
   ```
6. `nix flake check`, then build every host that should now have access to this secret.
7. Deploy and watch activation: `journalctl -u sops-nix -b` on the target host confirms decrypt success.

## Gotchas
- Committing before re-encrypting after a recipient change leaves the repo in a state where the new host cannot decrypt — activation will fail on first deploy. Always `sops updatekeys` after changing `.sops.yaml`.
- Default owner/mode for a sops secret is `root:root 0400`. Services running as a non-root user cannot read it — set `owner` explicitly.
- Do not `echo $SECRET` or `${SECRET:-fallback}` in any shell hook or activation script. Presence-checks against env vars leak the value. Test the file path instead.
- Do not print the secret from a Nix `trace`/`builtins.trace` while debugging — traces land in the build log.
- Rotating by replacing the value in-place is fine for the repo, but remember the old value may still be on hosts until the next activation. If compromised, deploy immediately, then revoke upstream.

## Verify
- [ ] The secret exists only inside an encrypted file under `secrets/`; grep the rest of the repo for the plaintext value and find nothing.
- [ ] `.sops.yaml` recipients match the set of hosts that need the secret.
- [ ] The module declares `sops.secrets.<name>` with correct owner/group/mode.
- [ ] Every consumer references `config.sops.secrets.<name>.path`, not a string literal.
- [ ] `nix flake check` passes; affected host(s) build.
- [ ] Post-deploy: file exists at the expected path with the expected ownership (`stat $(nix eval --raw .#nixosConfigurations.<host>.config.sops.secrets.<name>.path)`).

## Debug
- Activation error "no key could decrypt the data" → the host's age key isn't in the recipients for that path in `.sops.yaml`. Fix + `sops updatekeys` + redeploy.
- Secret exists but service can't read it → wrong `owner`/`mode` on the `sops.secrets.<name>` declaration.
- Secret seems to work locally but fails on host → you were relying on your user's age key; the host has its own. Confirm both are recipients for the file.

## Update Scaffold
- [ ] If this is the first secret of a new category (e.g. first DNS provider token), add a short note in `context/secrets.md` about the scope.
- [ ] Update `.mex/ROUTER.md` "Current Project State" if the fleet gained a new capability that this secret unlocked.
- [ ] If gotchas grew during this task, update the list above.
