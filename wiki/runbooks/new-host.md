# Adding a New Host

> **Automated path:** run `/onboard-host <name> <ssh-endpoint>` from Claude Code
> inside this repo. The skill drives the full flow (inspect → scaffold →
> deploy → commit → wiki stub) for fresh NixOS, Ubuntu-via-nixos-infect, and
> bare-metal rescue environments. The steps below are the manual fallback and
> the source of truth if the skill needs to be edited.

## Prerequisites

- NixOS installed on the target machine
- SSH access from your workstation
- Target machine's SSH host key

## Steps

1. **Generate hardware config** on the target:
   ```bash
   nixos-generate-config --show-hardware-config > hardware.nix
   ```

2. **Create the host directory** in the repo:
   ```bash
   mkdir -p hosts/<hostname>
   ```

3. **Copy hardware config**:
   ```bash
   cp hardware.nix hosts/<hostname>/hardware.nix
   ```

4. **Create `hosts/<hostname>/default.nix`**:
   ```nix
   { config, lib, pkgs, inputs, ... }:
   {
     imports = [
       ./hardware.nix
       # Host-role modules (opt-in):
       # ../../modules/vm-guest.nix
       # ../../modules/containers.nix
     ];

     boot.loader.systemd-boot.enable = true;  # or boot.loader.grub for BIOS/Hetzner
     boot.loader.efi.canTouchEfiVariables = true;
     system.stateVersion = "25.05";

     # Opt into the modular dev/tool stack as needed:
     # orbal.dev.enable = true;
     # orbal.languages = { node.enable = true; go.enable = true; };
     # orbal.claude.enable = true;
   }
   ```

5. **Register in `flake.nix`**:
   ```nix
   nixosConfigurations = {
     forge = mkHost "forge";
     seed  = mkHost "seed";
     <hostname> = mkHost "<hostname>";
   };
   ```

6. **Deploy**:
   ```bash
   nixos-rebuild switch --flake .#<hostname> --target-host <hostname>
   ```

7. **Register the host's tailnet IP** so `.orbal` DNS resolves for it:
   - On the new host (or any tailnet node): `tailscale status` to read its IPv4.
   - Append to `orbal.tailnetHosts` in `modules/tailnet-hosts.nix`:
     ```nix
     <hostname> = "100.x.y.z";
     ```
   - Rebuild seed so dnsmasq picks up the new record:
     ```bash
     nixos-rebuild switch --flake .#seed --target-host seed
     ```
   - Optionally opt the new host into `orbal.reverseProxy` to expose its services as `<service>.<hostname>.orbal`. See [Reverse proxy](../services/reverse-proxy.md).

8. **Update the wiki**: Add hardware specs and update network topology.
