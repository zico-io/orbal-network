---
name: architecture
description: How the major pieces of this project connect and flow. Load when working on system design, integrations, or understanding how components interact.
triggers:
  - "architecture"
  - "system design"
  - "how does X connect to Y"
  - "integration"
  - "flow"
  - "module"
  - "host"
edges:
  - target: context/stack.md
    condition: when specific technology details are needed
  - target: context/decisions.md
    condition: when understanding why the architecture is structured this way
  - target: context/secrets.md
    condition: when the change touches sops-encrypted values or secret wiring
  - target: context/conventions.md
    condition: when moving from understanding structure to actually writing a module or host change
  - target: context/network.md
    condition: when the change touches tailnet IPs, firewall, DNS, or service URLs
  - target: context/services/
    condition: when working on a specific service (reverse-proxy, local-llm, podman, tmux, agent-skills)
  - target: patterns/add-module.md
    condition: when introducing a new capability as a flake module
  - target: patterns/wire-module-into-host.md
    condition: when an existing module needs to be enabled on a host
last_updated: 2026-04-24
---

# Architecture

## System Overview
The flake is the single source of truth. `forge` is a dev VM on TrueNAS Scale (mother-brain). `seed` is a Hetzner Robot dedicated server (2× NVMe RAID1). Three HP Elitedesk mini-PCs currently run Proxmox; the long-term plan is bare-metal NixOS on all three joining this flake as additional hosts.

Change flow for any system modification:

1. Author or edit a module under `modules/<name>.nix` exposing an `orbal.<name>.enable` toggle.
2. Wire it into one or more hosts under `hosts/<host>/` (default.nix imports + option values).
3. Encrypt any needed secrets into `secrets/dev.yaml` (or a new sops-encrypted file under `secrets/`); reference them in the module via sops-nix.
4. Validate: `nix flake check` and `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
5. Deploy: `nixos-rebuild switch --flake .#<host> --target-host <host>` (or on-host `rebuild`).

Every host's runtime config is a pure function of the repo at HEAD — no imperative drift.

## Key Directories
- **flake.nix** — inputs (nixpkgs 25.05, home-manager, sops-nix, disko, claude-code, agent-skills) and the `mkHost` helper that assembles every host from shared modules + per-host config.
- **hosts/** — one directory per machine (`forge`, `seed` active; `elitedesk-1..3` planned). Each holds the host-specific NixOS config and disko layout.
- **modules/** — shared, toggleable capabilities. Each gated by `orbal.<name>.enable`. See the module table below.
- **secrets/** — sops-age encrypted YAML (`dev.yaml` today). Decryption keys are per-host; wiring happens in `modules/secrets.nix`.
- **overlays/** — package overlays applied via flake overlays output.
- **.mex/skills/** — local agent skills wired onto hosts via `modules/agents.nix` when `orbal.agents.skills` is enabled.

## Modules

| Module | Toggle | Contents |
|--------|--------|----------|
| `base.nix` | always-on | nix settings, timezone, tailscale, ssh, firewall |
| `users.nix` | always-on | `stperc` user + base git identity |
| `secrets.nix` | `orbal.secrets.enable` | sops-nix wiring for `github_token`, `ssh_private_key` |
| `shell.nix` | `orbal.shell.enable` | zsh/nushell/direnv/pure + ripgrep/fd/fzf + `rebuild` script |
| `cli.nix` | `orbal.cli.enable` | bat/eza/btop/atuin/zoxide/lazygit/gh/jq/yq/… + aliases |
| `git.nix` | `orbal.git.enable` | SSH-key signing, delta pager, allowed_signers |
| `tmux.nix` | `orbal.tmux.enable` | tmux config, `tmux-sessionizer`, SSH auto-attach |
| `editor.nix` | `orbal.editor.enable` | helix + `EDITOR`/`VISUAL` |
| `languages.nix` | `orbal.languages.{node,go,rust,python}.enable` | language toolchains |
| `agents.nix` | `orbal.agents.claude.enable`, `.skills.enable` | claude-code CLI + agent-skills-nix (skills contributed by modules) |
| `local-llm.nix` | `orbal.local-llm.enable`, `.webui.enable` | Ollama server + optional Open WebUI, tailscale-only, declarative pre-pull |
| `tailnet-hosts.nix` | always-on | shared `orbal.tailnetHosts` map (hostname → tailnet IPv4), consumed by the DNS resolver |
| `reverse-proxy.nix` | `orbal.reverseProxy.enable` | per-host Caddy exposing services as `<service>.<host>.orbal`, tailnet-only, plain HTTP |
| `dns-resolver.nix` | `orbal.dnsResolver.enable` | dnsmasq authoritative for `.orbal`, tailnet-only; runs on seed today |
| `dev.nix` | `orbal.dev.enable` | meta — turns on secrets/shell/cli/git/tmux/editor |
| `containers.nix`, `vm-guest.nix` | — | host-role specifics |

`orbal.languages.*` and `orbal.agents.*` stay independent of `orbal.dev.enable` so a non-dev host can still host agents, and a dev host can skip language toolchains or agents. Skills are contributed by the modules that own them: `agents.nix` bundles the default skill set when any agent is enabled, and `dev.nix` additionally contributes `commit-smart` when both `orbal.dev.enable` and an agent are on. Hosts may append extras to `orbal.agents.skills.list`.

## External Dependencies
- **Tailscale** — the tailnet. Hosts address each other over Tailscale; `modules/tailnet-hosts.nix` is the wiring. Auth keys are sops secrets.
- **sops + age** — secret encryption. Every secret file is committed encrypted; decryption keys are provisioned per host.
- **nixpkgs (release-25.05)** — pinned upstream via flake input; updates are deliberate `nix flake update` bumps.
- **Hetzner Robot / TrueNAS Scale / bare-metal** — host substrates for `seed`, `forge`, and the planned elitedesks respectively.
- **Unifi stack** — LAN networking is not managed by Nix. See `context/network.md`.

## Deployment

```
local machine → git push → (optional CI check) → nixos-rebuild switch --flake .#<host> --target-host <host>
```

## What Does NOT Exist Here
- No imperative configuration tooling (Ansible, Chef, Puppet, bash provisioning scripts).
- No plaintext secrets — ever. If a value is sensitive, it goes through sops.
- No out-of-repo modifications to hosts — if it's not in the flake, it isn't part of the system.
- No application code that belongs to a product — this repo is infra/config only; application services live in their own repos and are consumed as packages or containers.
