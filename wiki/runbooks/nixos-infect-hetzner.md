# nixos-infect — Hetzner VPS

Convert a fresh Hetzner Cloud VPS from Ubuntu to NixOS using [nixos-infect](https://github.com/elitak/nixos-infect), then onboard it into the zebes fleet.

## Prerequisites

- Hetzner Cloud VPS provisioned with Ubuntu 22.04 or 24.04
- Root SSH access to the VPS
- This repo cloned on your workstation

## 1. Provision the VPS

In Hetzner Cloud Console:

1. Create a new server (CX22 or larger recommended)
2. Select **Ubuntu 22.04** or **24.04** as the OS
3. Add your SSH public key under **SSH Keys**
4. Note the public IP after creation

Verify SSH works:
```bash
ssh root@<vps-ip>
```

## 2. Run nixos-infect

On the VPS:

```bash
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-24.11 bash -x 2>&1 | tee /tmp/infect.log
```

This will:
- Install Nix
- Build a minimal NixOS system
- Rewrite the bootloader (GRUB)
- Reboot automatically

The SSH session will drop when the server reboots. Wait 1-2 minutes, then reconnect:

```bash
ssh root@<vps-ip>
```

> **Note:** The SSH host key changes after infection. Remove the old key first:
> ```bash
> ssh-keygen -R <vps-ip>
> ```

## 3. Verify NixOS is running

```bash
cat /etc/os-release   # should say NixOS
nixos-version
```

## 4. Capture hardware config

On the VPS:

```bash
nixos-generate-config --show-hardware-config
```

Copy the output — you'll need it for the host directory.

## 5. Add host to the fleet

Follow the [Adding a New Host](new-host.md) runbook:

1. Create `hosts/<hostname>/` directory
2. Paste hardware config into `hosts/<hostname>/hardware.nix`
3. Create `hosts/<hostname>/default.nix`:
   ```nix
   { config, lib, pkgs, inputs, ... }:
   {
     imports = [
       ./hardware.nix
       # Add modules as needed:
       # ../../modules/containers.nix
     ];

     # Hetzner uses GRUB, not systemd-boot
     boot.loader.grub.enable = true;
     boot.loader.grub.device = "/dev/sda";

     system.stateVersion = "24.11";
   }
   ```
4. Register in `flake.nix`:
   ```nix
   <hostname> = mkHost "<hostname>";
   ```

## 6. Deploy your config

From your workstation:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host root@<vps-ip> --use-remote-sudo
```

Or on the VPS directly (clone the repo first):

```bash
cd /path/to/zebes
sudo nixos-rebuild switch --flake .#<hostname>
```

## 7. Post-infection cleanup

nixos-infect leaves behind a generated `/etc/nixos/configuration.nix`. Once your flake-based config is deployed, this file is unused. Optionally remove it:

```bash
rm -rf /etc/nixos
```

## Hetzner-specific notes

**GRUB, not systemd-boot:** Hetzner VPS uses BIOS boot (MBR), not EFI. Use `boot.loader.grub` instead of `boot.loader.systemd-boot`.

**Networking:** Hetzner uses DHCP by default. If you need a static IP or IPv6, configure it in your host's `default.nix`:
```nix
networking = {
  interfaces.eth0 = {
    useDHCP = true;
    # or static:
    # ipv4.addresses = [{ address = "x.x.x.x"; prefixLength = 32; }];
  };
};
```

**Firewall:** Hetzner has no external firewall by default (unless you configure one in Cloud Console). Ensure NixOS firewall is enabled and only expose what you need:
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 ];
};
```

**Rescue mode:** If something goes wrong, use Hetzner's rescue system (Linux live env) from the Cloud Console to mount and fix the disk.

## Troubleshooting

**nixos-infect fails mid-run:**
Check the log at `/tmp/infect.log`. Common causes:
- Insufficient disk space (need ~4 GB free)
- Insufficient RAM (1 GB minimum, 2 GB recommended)
- Network issues pulling nixpkgs

Destroy and reprovision the VPS — it's faster than debugging a half-infected system.

**Can't SSH after reboot:**
- Wait longer — first NixOS boot can take a minute
- Verify the VPS is running in Hetzner Console
- Check the VNC console from Hetzner for boot errors
- Try rescue mode if the system won't boot

**Wrong bootloader config:**
If the system doesn't boot, enter rescue mode, mount the root filesystem, and fix `boot.loader.grub.device` to match the actual disk (usually `/dev/sda`).
