# System Architecture

## Overview

The orbal homelab is a fleet of NixOS machines managed declaratively via a single flake.

**forge** is a dev VM running on TrueNAS Scale (mother-brain). **seed** is a Hetzner Robot dedicated server (2x NVMe RAID1). Both are managed as NixOS configurations in this flake.

Three **HP Elitedesk** mini-PCs currently run Proxmox. The long-term plan is bare-metal NixOS on all three, joining this flake as additional hosts.

## Network

Networking is handled by the Unifi stack (not managed by Nix). Tailscale is enabled fleet-wide for mesh connectivity. See [Network Topology](network-topology.md) for details.

## Secrets

Secrets (API keys, tokens) are managed with sops-nix. Encrypted files live in the repo under `secrets/`, decrypted at activation time using each host's SSH host key.

## Modules

`modules/` is split by concern, each file gating on its own `orbal.<feature>.enable`. Hosts opt in à la carte in `hosts/<name>/default.nix`.

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

## Deployment

```
local machine → git push → (optional CI check) → nixos-rebuild switch --flake .#<host> --target-host <host>
```
