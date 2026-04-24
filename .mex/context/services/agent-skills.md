# Agent Skills

## Overview

Declarative management of agent skills via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix). Lives in `modules/agents.nix`. Skills are contributed by the modules they belong to and activate whenever a host enables an agent — the host no longer curates a skill list.

- `orbal.agents.claude.enable` installs the Claude Code CLI.
- `orbal.agents.skills.enable` gates skill sync; defaults true whenever any agent is enabled.
- `orbal.agents.skills.list` is the merged skill list. Modules append their own bundle; hosts may append extras.

Skills are bundled at build time from pinned flake inputs and synced into `$CLAUDE_CONFIG_DIR/skills` (default `~/.claude/skills`) via home-manager activation. Claude Code auto-discovers them from that path.

## Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `agent-skills` | `github:Kyure-A/agent-skills-nix` | Home-manager module, bundler, activation scripts |
| `anthropic-skills` | `github:anthropics/skills` (flake = false) | Skill catalog (source tree) |

Both are pinned in `flake.lock`. `inputs` is threaded into home-manager via `home-manager.extraSpecialArgs` in `flake.nix` so the module can resolve `sources.anthropic.input = "anthropic-skills"` at eval time.

## Sources

Two sources are registered in `modules/agents.nix`:

- `anthropic` — upstream catalog at `anthropic-skills/skills` (pinned via flake input).
- `orbal` — local repo catalog at `./skills/`. Skills land at `~/.claude/skills/<skill-id>/` alongside upstream ones; Claude Code's loader only looks one level deep under `skills/`, so we can't use `idPrefix` to namespace them without hiding the skill. If a local ID collides with an upstream one, rename the local directory.

## Currently enabled

In `hosts/forge/default.nix`:

```nix
orbal.agents.claude.enable = true;
```

That one toggle brings in the default skill bundle; `commit-smart` also flows in because forge has `orbal.dev.enable = true`. Resolved list on forge:

- `skill-creator` — scaffolds new SKILL.md directories. *(default bundle — `agents.nix`)*
- `onboard-host` — local skill: inspects a new machine, scaffolds `hosts/<name>/`, deploys, commits, and stubs the hardware profile. See `/onboard-host` usage in `skills/onboard-host/SKILL.md`. *(default bundle — `agents.nix`)*
- `skill-review` — local skill: grades a SKILL.md against the Tessl rubric (validation checks + Activation + Content scores). See `/skill-review` usage in `skills/skill-review/SKILL.md`. *(default bundle — `agents.nix`)*
- `skill-optimize` — local skill: iteratively rewrites a SKILL.md to raise its review score, with per-iteration diff + confirmation. See `/skill-optimize` usage in `skills/skill-optimize/SKILL.md`. *(default bundle — `agents.nix`)*
- `commit-smart` — local skill: analyzes staged changes and writes conventional commits. *(contributed by `dev.nix` when an agent is also enabled)*

`mcp-builder` and `claude-api` were removed from the default bundle on 2026-04-24 — they're upstream Anthropic skills aimed at application-development workflows that don't apply to this infra-only repo. Re-add at the host level (`orbal.agents.skills.list = [ "claude-api" ];`) if you start building Claude-consuming services on a specific host.

Verify the resolved list on any host:

```sh
nix eval .#nixosConfigurations.<host>.config.orbal.agents.skills.list
```

## Adding an upstream skill

Decide where the skill should come from:

- **Bundle with all agents by default** — append the ID to the default list in `modules/agents.nix` (the `mkIf cfg.anyEnabled` block). Every host with any agent enabled picks it up.
- **Bundle only when another module is enabled** — in that module (e.g. `modules/dev.nix`), add a `mkIf (cfg.enable && config.orbal.agents.anyEnabled)` block that appends to `orbal.agents.skills.list`.
- **Host-level extra** — append directly in the host config: `orbal.agents.skills.list = [ "<skill-id>" ];`. Nix merges list definitions automatically.

Then `rebuild switch`.

List what's available upstream: `gh api repos/anthropics/skills/contents/skills --jq '.[] | select(.type=="dir") | .name'`.

To pin a different catalog, add a new input in `flake.nix` and register it as an additional source (`sources.<name>.input = "<input-name>";`). Claude Code's skill loader only discovers skills one level deep under `~/.claude/skills/`, so `idPrefix` can't be used to namespace colliding IDs — rename one side instead.

## Adding a local skill

Local skills live under `./skills/<skill-id>/SKILL.md` at the repo root and are exposed via the `orbal` source.

1. `mkdir skills/<skill-id>` and write `SKILL.md` with the `name` / `description` frontmatter (see `skills/commit-smart/SKILL.md` for a reference).
2. `git add skills/<skill-id>/SKILL.md` — flake sources only include Git-tracked files, so untracked skills won't make it into the store.
3. Wire it into a module (or a host's `orbal.agents.skills.list`) using the same placement rules as upstream skills above.
4. Rebuild: `rebuild switch`.

## Updating the catalog

```sh
nix flake lock --update-input anthropic-skills
rebuild switch
```

## Uninstall

Set `orbal.agents.skills.enable = false;` and rebuild — home-manager's activation script clears the rsync-managed tree. The agent CLI stays installed. To remove both, set `orbal.agents.claude.enable = false;` too. To drop the integration entirely, remove the `orbal.agents` block from the host config; to also drop the inputs, remove `agent-skills` and `anthropic-skills` from `flake.nix`.

## Diagnostics

- List catalog contents: `nix run .#skills-list` (from a flake exposing the same config, not the orbal-network root).
- Inspect the bundle: `ls $(nix build --no-link --print-out-paths .#nixosConfigurations.forge.config.home-manager.users.stperc.home.activationPackage)` and look under `home-files/.claude/skills`.
- The module uses `rsync -a --delete`; if the target dir contains non-Nix-managed files, activation will clobber them. Back up before first switch if you had hand-placed skills in `~/.claude/skills`.
