# forge — NixOS Dev VM on TrueNAS Scale

Remote development VM running on TrueNAS Scale (ElectricEel-24.10.2).

## Build the image

```bash
nix build .#nixosConfigurations.forge.config.system.build.forgeImage
```

Output: `result/nixos.qcow2`

Transfer to TrueNAS:
```bash
scp result/nixos.qcow2 root@<truenas-ip>:/mnt/<pool>/images/
```

## Create VM in TrueNAS

### Prerequisites

1. **Network bridge** — if not already configured:
   - TrueNAS UI → Network → Interfaces → Add
   - Type: Bridge, member: physical NIC
   - Save and apply

### VM creation

1. Virtualization → Add
2. **Guest OS:** Linux, UTC clock
3. **CPU & Memory:** 4 vCPUs, 16384 MB RAM
4. **Disk:** Import Image → browse to `nixos.qcow2`, select target pool, VirtIO type
5. **Network:** Select bridge interface, VirtIO NIC
6. **Display:** VNC enabled (emergency console only)
7. **Installation Media:** skip (image is pre-built)
8. Create → VM starts automatically

## First boot

The VM will:
- Boot via systemd-boot (EFI)
- Get a DHCP address from the Unifi network
- Auto-expand the root partition to fill the zvol
- Generate SSH host keys

Find the IP:
- Check your Unifi controller for new DHCP lease named `forge`
- Or use TrueNAS VNC console to check `ip addr`

SSH in:
```bash
ssh stperc@<forge-ip>
```

## Day-2 operations

### Rebuild from flake

From the VM:
```bash
sudo nixos-rebuild switch --flake github:zico-io/zebes#forge
```

Or from any machine with SSH access:
```bash
nixos-rebuild switch --flake .#forge --target-host stperc@<forge-ip> --use-remote-sudo
```

### Rebuild the image

After config changes, rebuild and re-import:
```bash
nix build .#nixosConfigurations.forge.config.system.build.forgeImage
```

Note: for running VMs, prefer `nixos-rebuild switch` over re-imaging.

### Resize disk

1. TrueNAS UI → Storage → expand the zvol
2. Reboot the VM (or run `growpart` + `resize2fs` manually)
   The first-boot service only runs once; for subsequent resizes:
   ```bash
   sudo rm /var/lib/.disk-expanded
   sudo systemctl start expand-root
   ```

### Snapshots

TrueNAS automatically manages ZFS snapshots for zvols. Manual snapshot:
- Storage → Snapshots → Add → select the forge zvol

## Optional: NFS shared storage

To mount TrueNAS datasets inside forge:

1. TrueNAS UI → Shares → Unix (NFS) → Add share for your dataset
2. Add to forge NixOS config:
   ```nix
   fileSystems."/mnt/nas" = {
     device = "<truenas-ip>:/mnt/<pool>/<dataset>";
     fsType = "nfs";
     options = [ "x-systemd.automount" "noauto" ];
   };
   ```
3. `nixos-rebuild switch`
