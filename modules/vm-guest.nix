{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.zebes.vm-guest;
in
{
  options.zebes.vm-guest = {
    enable = mkEnableOption "KVM/QEMU virtual machine guest services";
  };

  config = mkIf cfg.enable {
    services.qemuGuest.enable = true;

    # Serial console for TrueNAS serial shell access
    systemd.services."serial-getty@ttyS0".enable = true;

    # Expand root partition to fill the zvol on first boot
    systemd.services."expand-root" = {
      description = "Expand root partition and filesystem on first boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      unitConfig.ConditionPathExists = "!/var/lib/.disk-expanded";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.cloud-utils}/bin/growpart /dev/vda 2 || true
        ${pkgs.e2fsprogs}/bin/resize2fs /dev/vda2 || true
        touch /var/lib/.disk-expanded
      '';
    };
  };
}
