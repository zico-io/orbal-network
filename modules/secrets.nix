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
  };
}
