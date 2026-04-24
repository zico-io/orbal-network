{ config, lib, ... }:

with lib;

let
  cfg = config.orbal.secrets;
in
{
  options.orbal.secrets.enable =
    mkEnableOption "sops-managed dev secrets (github_token, ssh_private_key)";

  config = mkIf cfg.enable {
    sops.defaultSopsFile = ../secrets/dev.yaml;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    sops.secrets."github_token" = {
      owner = "stperc";
      mode = "0400";
    };
    sops.secrets."ssh_private_key" = {
      owner = "stperc";
      mode = "0600";
      path = "/home/stperc/.ssh/id_ed25519";
    };

    # sops auto-creates /home/stperc/.ssh as root:root 755 when it places the key
    # symlink there, which blocks stperc from writing known_hosts or adding its
    # own keys. Force ownership/perms so the directory is stperc's to manage.
    systemd.tmpfiles.rules = [
      "d /home/stperc/.ssh 0700 stperc users -"
    ];
  };
}
