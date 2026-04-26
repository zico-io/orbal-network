---
name: router
description: Session bootstrap and navigation hub. Read at the start of every session before any task. Contains project state, routing table, and behavioural contract.
edges:
  - target: context/architecture.md
    condition: when working on system design, integrations, or understanding how components connect
  - target: context/stack.md
    condition: when working with specific technologies, libraries, or making tech decisions
  - target: context/conventions.md
    condition: when writing new code, reviewing code, or unsure about project patterns
  - target: context/decisions.md
    condition: when making architectural choices or understanding why something is built a certain way
  - target: context/setup.md
    condition: when setting up the dev environment or running the project for the first time
  - target: context/secrets.md
    condition: when the task touches sops-encrypted values, age keys, or any sensitive material
  - target: context/network.md
    condition: when the task touches tailnet IPs, firewall, DNS, or service URLs
  - target: context/services/
    condition: when working on a specific service (reverse-proxy, local-llm, podman, tmux, agent-skills)
  - target: context/hardware/
    condition: when the task concerns a specific physical machine's hardware profile
  - target: patterns/INDEX.md
    condition: when starting a task — check the pattern index for a matching pattern file
  - target: patterns/runbooks/
    condition: when running an operational procedure (first deploy, rebuild, disaster recovery, forge VM, new host, nixos-infect)
last_updated: 2026-04-25
---

# Session Bootstrap

If you haven't already read `AGENTS.md`, read it now — it contains the project identity, non-negotiables, and commands.

Then read this file fully before doing anything else in this session.

## Current Project State
**Working:**
- Flake builds two hosts: `forge` (TrueNAS Scale dev VM) and `seed` (Hetzner Robot dedicated).
- Core shared modules: base, users, secrets (sops-nix), shell, cli, git, tmux, editor, languages, agents, local-llm, tailnet-hosts, reverse-proxy, dns-resolver, dev, containers, vm-guest.
- `modules/languages.nix` now includes `orbal.languages.typescript.enable` (tsc + typescript-language-server).
- `devShells.x86_64-linux.bask` added to flake: bun + typescript + typescript-language-server + pnpm_8.
- Sops-encrypted secrets via `secrets/dev.yaml` and `.sops.yaml` recipient rules. (`github_token` removed; GitHub auth now via `gh auth login` — `gh` wired in `modules/cli.nix` with git credential helper enabled.)
- Overlays wired through `overlays/default.nix`.
- Local agent skills wired onto hosts via `modules/agents.nix` when `orbal.agents.skills` is enabled (source in `.mex/skills/`).
- Single agent tree: `.mex/` absorbs the former `wiki/` **and** the former top-level `skills/` — runbooks live under `.mex/patterns/runbooks/`, services under `.mex/context/services/`, hardware under `.mex/context/hardware/`, network under `.mex/context/network.md`, decisions (including ADR-001/002/003) in `.mex/context/decisions.md`, local Claude skills under `.mex/skills/`.

**Not yet built:**
- `elitedesk-1`, `elitedesk-2`, `elitedesk-3` bare-metal hosts (planned per README).
- Scoped/split secret files beyond `dev.yaml`.
- Documented human-contributor age-key onboarding flow.
- Any CI pipeline running `nix flake check` on PRs. [VERIFY AFTER FIRST IMPLEMENTATION]

**Known issues:**
- Some runbooks migrated from the former wiki still use wiki-style phrasing rather than the agent-oriented pattern format; refactor lazily as each is touched.

## Routing Table

Load the relevant file based on the current task. Always load `context/architecture.md` first if not already in context this session.

| Task type | Load |
|-----------|------|
| Understanding how the system works | `context/architecture.md` |
| Working with a specific technology | `context/stack.md` |
| Writing or reviewing code | `context/conventions.md` |
| Making a design decision | `context/decisions.md` |
| Setting up or running the project | `context/setup.md` |
| Anything touching secrets / sops / age | `context/secrets.md` |
| Tailnet / firewall / DNS / service URLs | `context/network.md` |
| Working on a specific service | `context/services/<name>.md` (reverse-proxy, local-llm, podman, tmux, agent-skills) |
| A physical machine's hardware profile | `context/hardware/<name>.md` |
| Adding a new flake module | `patterns/add-module.md` |
| Wiring a module into a host | `patterns/wire-module-into-host.md` |
| Adding or rotating a sops secret | `patterns/add-secret.md` |
| Running an operational procedure | `patterns/runbooks/<name>.md` (first-deploy, rebuild, new-host, disaster-recovery, forge-vm, nixos-infect-hetzner) |
| Any specific task | Check `patterns/INDEX.md` for a matching pattern |

## Behavioural Contract

For every task, follow this loop:

1. **CONTEXT** — Load the relevant context file(s) from the routing table above. Check `patterns/INDEX.md` for a matching pattern. If one exists, follow it. Narrate what you load: "Loading architecture context..."
2. **BUILD** — Do the work. If a pattern exists, follow its Steps. If you are about to deviate from an established pattern, say so before writing any code — state the deviation and why.
3. **VERIFY** — Load `context/conventions.md` and run the Verify Checklist item by item. State each item and whether the output passes. Do not summarise — enumerate explicitly.
4. **DEBUG** — If verification fails or something breaks, check `patterns/INDEX.md` for a debug pattern. Follow it. Fix the issue and re-run VERIFY.
5. **GROW** — After completing the task:
   - If no pattern exists for this task type, create one in `patterns/` using the format in `patterns/README.md`. Add it to `patterns/INDEX.md`. Flag it: "Created `patterns/<name>.md` from this session."
   - If a pattern exists but you deviated from it or discovered a new gotcha, update it with what you learned.
   - If any `context/` file is now out of date because of this work, update it surgically — do not rewrite entire files.
   - Update the "Current Project State" section above if the work was significant.
