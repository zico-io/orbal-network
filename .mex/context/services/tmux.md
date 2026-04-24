# tmux

## Overview

Declarative tmux workflow for dev hosts (currently `forge`). Lives in `modules/tmux.nix` under the `orbal.tmux.enable` toggle; `orbal.dev.enable = true` turns it on by default as part of the dev bundle.

Three pieces:

1. **tmux config** (`programs.tmux`) — prefix `C-a`, vi keys, mouse on, 256-color + truecolor, sensible/resurrect/continuum plugins pinned via nix.
2. **`tmux-sessionizer`** — fzf-driven project picker. Creates or attaches to a named session with a fixed 3-pane layout.
3. **SSH auto-attach** — zsh (`initContent`) and nushell (`loginFile`) attach to a `main` session on SSH login when not already inside tmux.

## Keybinds

Prefix is `C-a` (replaces default `C-b`). All binds below are `prefix` then key.

| Key | Action |
|-----|--------|
| `f` | Open sessionizer popup (fzf over project dirs) |
| `h` / `j` / `k` / `l` | Move between panes (vi-style, repeatable) |
| `|` | Split pane horizontally, preserve CWD |
| `-` | Split pane vertically, preserve CWD |
| `r` | Reload `~/.config/tmux/tmux.conf` |
| `d` | Detach (standard) |
| `s` | Session list (standard) |

## Per-project layout

Created once per new session by the sessionizer:

```
┌──────────────────────┬───────────────┐
│                      │   shell       │
│       helix          ├───────────────┤
│   (project root)     │   scratch     │
│                      │               │
└──────────────────────┴───────────────┘
```

- Window `edit`: left pane opens `hx .`; right column is two stacked shells.
- Window `shell`: full-width shell in the project root.

## Sessionizer

```bash
# From inside tmux
<prefix>f

# From any shell (creates or attaches)
tmux-sessionizer

# Target a specific directory
tmux-sessionizer /home/stperc/orbal-network
```

Project discovery: the script searches `$HOME` and `$HOME/src` (if present) for `.git` dirs up to 4 levels deep. To add another root, edit `SEARCH_ROOTS` at the top of the `writeShellApplication` block in `modules/dev.nix`.

Session name = basename of the project dir with `.` → `-` (tmux rejects `.` in session names).

## Auto-attach

SSH into `forge` and you land inside a tmux session named `main`. The guards are strict — auto-attach only fires when:

- `$TMUX` is unset (not already inside tmux), **and**
- `$SSH_TTY` is set (this is an SSH login, not a local console), **and**
- `tmux` is on `PATH`.

Local ttys and subshells inside tmux get a plain shell.

## Persistence

`tmuxPlugins.resurrect` + `tmuxPlugins.continuum` save session state every 15 minutes and auto-restore on tmux start. After a `nixos-rebuild switch` or reboot, the prior sessions come back a few seconds after login.

## Changing prefix / keybinds

Edit `programs.tmux.prefix` (top-level option) or `programs.tmux.extraConfig` in `modules/dev.nix`, then `nixos-rebuild switch`. Reload an already-running tmux with `<prefix>r` — no need to kill sessions.
