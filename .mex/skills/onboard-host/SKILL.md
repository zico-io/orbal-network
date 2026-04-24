---
name: onboard-host
description: Inspect a new host, scaffold an optimal hosts/<name>/ flake entry, deploy it, commit, and stub the hardware profile. Handles fresh NixOS over SSH, Ubuntu/Debian via nixos-infect, and bare-metal rescue envs via nixos-anywhere. Use when onboarding a new machine into the orbal fleet — e.g. the user says "add this elitedesk", "onboard a new Hetzner VPS", "bring this box into the flake", or points at a rescue/SSH endpoint for a machine that should become an orbal host. Usage - /onboard-host, /onboard-host elitedesk-1 root@10.0.0.42
---

# Onboard Host

End-to-end onboarding for a new orbal fleet member. Inspects the target, infers
a flake config, deploys, commits, and stubs the hardware profile. Stop and surface errors
rather than retrying destructively — an onboard that half-completes is recoverable,
one that wipes the wrong disk is not.

## Workflow

### Step 1: Intake

Parse `$ARGUMENTS` — up to two positional tokens: `<hostname>` and
`<ssh-endpoint>` (e.g. `elitedesk-1 root@10.0.0.42`). Ask for anything missing.

Then use AskUserQuestion to pick the **starting state** of the target. This
determines the rest of the flow:

- **`nixos-ssh`** — NixOS already installed, reachable over SSH as a wheel user
  (or root). Straight onboard path.
- **`ubuntu-infect`** — Ubuntu/Debian VPS with root SSH. Run nixos-infect first,
  then fall through to the NixOS path. Matches the seed/Hetzner flow.
- **`bare-metal`** — Booted into a rescue environment (Hetzner rescue, NixOS
  installer ISO, etc.) with root SSH. Provision via nixos-anywhere in Step 6.

If `bare-metal`, ask a follow-up with AskUserQuestion for the **disk layout**:

- **`single-disk-efi`** (default) — one disk, GPT, 512M ESP + ext4 root
- **`dual-disk-raid1`** — two NVMe disks, mdraid1 root (mirrors `hosts/seed/disk-config.nix`)
- **`custom`** — stop here and tell the user to hand-author `hosts/<name>/disk-config.nix`
  before re-invoking the skill

### Step 2: OS prep (branch)

- **`nixos-ssh`:** skip.
- **`ubuntu-infect`:** walk the nixos-infect procedure (cribbed from
  `.mex/patterns/runbooks/nixos-infect-hetzner.md`):
  ```bash
  ssh <endpoint> 'curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-25.05 bash -x 2>&1 | tee /tmp/infect.log'
  ```
  The session will drop when the VPS reboots. Wait ~2 min, then locally run:
  ```bash
  ssh-keygen -R <host-or-ip>
  ```
  Verify by `ssh <endpoint> 'cat /etc/os-release; nixos-version'`. Confirm it's NixOS before continuing.
- **`bare-metal`:** do *not* run anything yet. Just verify `ssh <endpoint> 'lsblk; ip -br a'`
  and confirm the block devices match the chosen disk layout (1 disk for
  `single-disk-efi`, ≥2 for `dual-disk-raid1`). If they don't match, stop.

### Step 3: Inspect the target

For `nixos-ssh` and `ubuntu-infect` (post-infect), gather facts:

```bash
ssh <endpoint> 'nixos-generate-config --show-hardware-config' > /tmp/onboard-hardware.nix
ssh <endpoint> 'lscpu | head -20'
ssh <endpoint> 'free -h'
ssh <endpoint> 'lsblk -o NAME,SIZE,MODEL,ROTA,TYPE,MOUNTPOINT'
ssh <endpoint> 'ip -br a; echo ---; ip route | head -5'
ssh <endpoint> 'systemd-detect-virt || true'
ssh <endpoint> 'lspci -nnk 2>/dev/null | grep -iE "vga|3d|nvme" || true'
ssh <endpoint> '[ -d /sys/firmware/efi ] && echo EFI || echo BIOS'
```

For `bare-metal`, skip the `nixos-generate-config` call (no NixOS yet). Still
collect the rest from the rescue env — they inform the default.nix.

Show the user a short summary of what was detected before moving on.

### Step 4: Infer toggles

Build a **proposed** `hosts/<name>/default.nix`. Use the signal table in
**Reference** below to decide:

- bootloader (systemd-boot vs grub)
- whether to import `modules/vm-guest.nix` + set `orbal.vm-guest.enable = true`
- whether to include the raid/swraid block
- whether static networking is needed (public IPv4 on primary interface)

Then use AskUserQuestion (`multiSelect: true`) to let the user opt into the
optional modules. The catalogue (from `flake.nix`):

- `orbal.dev.enable` — dev tooling (implies `orbal.secrets.enable`)
- `orbal.languages.{node,go,rust,python}.enable` — language toolchains
- `orbal.agents.claude.enable` — Claude Code CLI (auto-enables `orbal.agents.skills`; see `modules/agents.nix` for the default skill list and `.mex/context/services/agent-skills.md` for how to add or override)
- `orbal.containers.enable` — container runtime
- `orbal.local-llm.enable` (+ `webui.enable`) — Ollama + Open WebUI
- `orbal.reverseProxy.enable` — expose services on `<svc>.<name>.orbal`
- `orbal.dnsResolver.enable` — run dnsmasq for `.orbal` (only one host should own this; currently seed)

Render the full proposed `default.nix` in a fenced block and wait for
confirmation or edits. Do **not** write files until the user confirms.

### Step 5: Scaffold files

Create the host directory:

```bash
mkdir -p hosts/<name>
```

Write files (via the Write tool, not cat/echo):

- `hosts/<name>/hardware.nix` — paste from `/tmp/onboard-hardware.nix` (skip for `bare-metal`)
- `hosts/<name>/disk-config.nix` — for `bare-metal` only, from the chosen template
- `hosts/<name>/default.nix` — the confirmed synthesis from Step 4. Always set
  `system.stateVersion = "25.05"`.

Register the host in `flake.nix`. If the name is `elitedesk-1/2/3`, uncomment
the matching line; otherwise add a new line after the last active host:

```nix
<name> = mkHost "<name>";
```

### Step 6: Build check + deploy

Always dry-build first — evaluation errors are much cheaper to fix locally than
mid-deploy:

```bash
nix build .#nixosConfigurations.<name>.config.system.build.toplevel --no-link
```

If it fails, fix and re-run. Only once it succeeds, deploy:

- **`nixos-ssh`** or **`ubuntu-infect`:**
  ```bash
  nixos-rebuild switch --flake .#<name> --target-host <endpoint> --use-remote-sudo
  ```
- **`bare-metal`:**
  ```bash
  nix run github:nix-community/nixos-anywhere -- --flake .#<name> <endpoint>
  ```
  nixos-anywhere reads the disko config from the flake, partitions the disks,
  installs NixOS, and reboots. Destructive — confirm the endpoint and disk
  layout one more time with the user before running.

If deploy fails, stop. Surface stderr to the user. Do not retry with
`--impure`, `--no-verify`, or any other flag that changes safety posture.

### Step 7: Post-deploy

**Verify:**
```bash
ssh <name> nixos-version
ssh <name> which rebuild        # proves modules/shell.nix wrapper is live
ssh <name> tailscale status
```

**Stub the hardware profile.** Write `.mex/context/hardware/<name>.md` using the shape of
`.mex/context/hardware/elitedesk.md`. Fill the table with what you detected in Step 3
(model, CPU, RAM, storage, primary NIC).

**Update the host table** in `README.md`. If the name is `elitedesk-1/2/3`,
flip `Planned` → `Active`. Otherwise append a new row.

**Commit** using the conventional-commit style from the `commit-smart` skill.
Stage only:

```bash
git add hosts/<name>/ flake.nix flake.lock .mex/context/hardware/<name>.md README.md
```

Suggested subject: `feat(hosts): onboard <name>`. Body explains *why* this host
was added (role, what it replaces, anything non-obvious).

### Step 8: Surface manual follow-ups

Always end by listing what the user must still do by hand (do **not** attempt
to automate these):

1. **Tailnet registration.** On the new host: `tailscale status`, copy its IPv4.
   Append to `orbal.tailnetHosts` in `modules/tailnet-hosts.nix`. Rebuild seed
   so `.orbal` DNS picks it up:
   ```bash
   nixos-rebuild switch --flake .#seed --target-host seed
   ```
2. **sops enrollment** (only if the final config had `orbal.dev.enable = true` or
   `orbal.secrets.enable = true`). Procedure in `.mex/patterns/runbooks/first-deploy.md`
   §4: derive the age recipient with `ssh-to-age`, add it to `.sops.yaml`,
   `sops updatekeys secrets/dev.yaml`.

## Tips

- If the user provides neither hostname nor endpoint, ask once and proceed —
  don't loop.
- For `ubuntu-infect`, the SSH host key changes after reboot. Expect to re-accept it.
- `nixos-anywhere` wipes disks. Before running it, echo the endpoint and
  `lsblk` output one last time and wait for explicit user confirmation.
- If the dry-build reveals an `inputs` that the new host needs which isn't yet
  a flake input (e.g. a GPU driver overlay), stop and raise it — don't hand-edit
  `flake.nix` to add inputs as a side-effect of onboarding.

---

## Reference

### Inference signals → default.nix

| Signal (from Step 3) | Effect on `hosts/<name>/default.nix` |
|---|---|
| `/sys/firmware/efi` present | `boot.loader.systemd-boot.enable = true; boot.loader.efi.canTouchEfiVariables = true;` |
| No `/sys/firmware/efi` | `boot.loader.grub` block modeled on `hosts/seed/default.nix` |
| `systemd-detect-virt` = `kvm` / `qemu` / `microvm` | `imports = [ ../../modules/vm-guest.nix ];` + `orbal.vm-guest.enable = true;` |
| `systemd-detect-virt` = `none` | bare-metal, no vm-guest import |
| Chose `dual-disk-raid1` in Step 1 | `boot.swraid = { enable = true; mdadmConf = "MAILADDR root"; };` |
| Primary interface has a public (non-RFC1918) IPv4 | static `networking.interfaces.<nic>` + `defaultGateway` block modeled on `hosts/seed/default.nix` |
| Primary interface is RFC1918 / LAN | leave `networking.useDHCP = lib.mkDefault true;` from hardware.nix |
| ≥1 discrete GPU in `lspci` output | flag to user — orbal has no GPU module yet, may need a new module or overlay |

### Deploy command cheat sheet

| Start state | Command |
|---|---|
| `nixos-ssh` | `nixos-rebuild switch --flake .#<name> --target-host <endpoint> --use-remote-sudo` |
| `ubuntu-infect` (post-infect) | same as above |
| `bare-metal` | `nix run github:nix-community/nixos-anywhere -- --flake .#<name> <endpoint>` |

### Disk layout templates

**`single-disk-efi`** — write as `hosts/<name>/disk-config.nix`, substituting
the detected disk device (usually `/dev/sda` or `/dev/nvme0n1`):

```nix
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/DISK";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
        };
        root = {
          size = "100%";
          content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
        };
      };
    };
  };
}
```

**`dual-disk-raid1`** — copy `hosts/seed/disk-config.nix` verbatim, substitute
the detected disk devices.

### default.nix skeleton

```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # ./hardware.nix        # nixos-ssh / ubuntu-infect
    # ./disk-config.nix     # bare-metal
    # ../../modules/vm-guest.nix  # if virtualized
    # ../../modules/containers.nix
  ];

  # bootloader block (systemd-boot OR grub)

  # networking block (only if static)

  # orbal.* toggles (confirmed with user in Step 4)

  system.stateVersion = "25.05";
}
```
