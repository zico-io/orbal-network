# Agent Skills

## Overview

Declarative management of Claude Code agent skills via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix). Lives in `modules/claude.nix`, opt-in via `orbal.claude.agentSkills.enable = true` (requires `orbal.claude.enable = true`). Independent of the dev bundle — enable per-host regardless of `orbal.dev.enable`.

Skills are bundled at build time from pinned flake inputs and synced into `$CLAUDE_CONFIG_DIR/skills` (default `~/.claude/skills`) via home-manager activation. Claude Code auto-discovers them from that path.

## Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `agent-skills` | `github:Kyure-A/agent-skills-nix` | Home-manager module, bundler, activation scripts |
| `anthropic-skills` | `github:anthropics/skills` (flake = false) | Skill catalog (source tree) |

Both are pinned in `flake.lock`. `inputs` is threaded into home-manager via `home-manager.extraSpecialArgs` in `flake.nix` so the module can resolve `sources.anthropic.input = "anthropic-skills"` at eval time.

## Sources

Two sources are registered in `modules/claude.nix`:

- `anthropic` — upstream catalog at `anthropic-skills/skills` (pinned via flake input).
- `orbal` — local repo catalog at `./skills/`. Skills land at `~/.claude/skills/<skill-id>/` alongside upstream ones; Claude Code's loader only looks one level deep under `skills/`, so we can't use `idPrefix` to namespace them without hiding the skill. If a local ID collides with an upstream one, rename the local directory.

## Currently enabled

In `hosts/forge/default.nix`:

```nix
orbal.claude = {
  enable = true;
  agentSkills = {
    enable = true;
    skills = [ "skill-creator" "mcp-builder" "claude-api" "commit-smart" "onboard-host" ];
  };
};
```

- `skill-creator` — scaffolds new SKILL.md directories.
- `mcp-builder` — helpers for authoring MCP servers.
- `claude-api` — Anthropic SDK reference material.
- `commit-smart` — local skill: analyzes staged changes and writes conventional commits.
- `onboard-host` — local skill: inspects a new machine, scaffolds `hosts/<name>/`, deploys, commits, and stubs the wiki. See `/onboard-host` usage in `skills/onboard-host/SKILL.md`.

## Adding an upstream skill

1. List what's available in the upstream catalog: `gh api repos/anthropics/skills/contents/skills --jq '.[] | select(.type=="dir") | .name'`.
2. Append the ID to `orbal.claude.agentSkills.skills` in the host config (e.g. `hosts/forge/default.nix`).
3. Rebuild: `rebuild switch`.

To pin a different catalog, add a new input in `flake.nix` and register it as an additional source (`sources.<name>.input = "<input-name>";`). Claude Code's skill loader only discovers skills one level deep under `~/.claude/skills/`, so `idPrefix` can't be used to namespace colliding IDs — rename one side instead.

## Adding a local skill

Local skills live under `./skills/<skill-id>/SKILL.md` at the repo root and are exposed via the `orbal` source.

1. `mkdir skills/<skill-id>` and write `SKILL.md` with the `name` / `description` frontmatter (see `skills/commit-smart/SKILL.md` for a reference).
2. `git add skills/<skill-id>/SKILL.md` — flake sources only include Git-tracked files, so untracked skills won't make it into the store.
3. Append `"<skill-id>"` to `orbal.claude.agentSkills.skills` in the host config.
4. Rebuild: `rebuild switch`.

## Updating the catalog

```sh
nix flake lock --update-input anthropic-skills
rebuild switch
```

## Uninstall

Set `orbal.claude.agentSkills.enable = false;` and rebuild — home-manager's activation script clears the rsync-managed tree. To drop the integration entirely, remove `orbal.claude.agentSkills` from the host config; to also drop the inputs, remove `agent-skills` and `anthropic-skills` from `flake.nix`.

## Diagnostics

- List catalog contents: `nix run .#skills-list` (from a flake exposing the same config, not the orbal-network root).
- Inspect the bundle: `ls $(nix build --no-link --print-out-paths .#nixosConfigurations.forge.config.home-manager.users.stperc.home.activationPackage)` and look under `home-files/.claude/skills`.
- The module uses `rsync -a --delete`; if the target dir contains non-Nix-managed files, activation will clobber them. Back up before first switch if you had hand-placed skills in `~/.claude/skills`.
