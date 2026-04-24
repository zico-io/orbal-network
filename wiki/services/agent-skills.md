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

## Currently enabled

In `hosts/forge/default.nix`:

```nix
orbal.claude = {
  enable = true;
  agentSkills = {
    enable = true;
    skills = [ "skill-creator" "mcp-builder" "claude-api" ];
  };
};
```

- `skill-creator` — scaffolds new SKILL.md directories.
- `mcp-builder` — helpers for authoring MCP servers.
- `claude-api` — Anthropic SDK reference material.

## Adding a skill

1. List what's available in the upstream catalog: `gh api repos/anthropics/skills/contents/skills --jq '.[] | select(.type=="dir") | .name'`.
2. Append the ID to `orbal.claude.agentSkills.skills` in the host config (e.g. `hosts/forge/default.nix`).
3. Rebuild: `rebuild switch`.

To pin a different catalog, add a new input in `flake.nix` and register it as an additional source (`sources.<name>.input = "<input-name>";`). If two sources expose the same skill ID, set `idPrefix` on each to namespace them.

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
