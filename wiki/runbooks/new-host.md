# Adding a New Host

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
       # Add modules as needed:
       # ../../modules/containers.nix
     ];

     boot.loader.systemd-boot.enable = true;
     boot.loader.efi.canTouchEfiVariables = true;
     system.stateVersion = "25.05";
   }
   ```

5. **Register in `flake.nix`**:
   ```nix
   nixosConfigurations = {
     orbal = mkHost "orbal";
     <hostname> = mkHost "<hostname>";
   };
   ```

6. **Deploy**:
   ```bash
   nixos-rebuild switch --flake .#<hostname> --target-host <hostname>
   ```

7. **Update the wiki**: Add hardware specs and update network topology.
