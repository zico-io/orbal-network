{ config, lib, ... }:

with lib;

let
  cfg = config.orbal.git;
  sshPubKey = builtins.elemAt config.users.users.stperc.openssh.authorizedKeys.keys 0;
in
{
  options.orbal.git.enable =
    mkEnableOption "git signing via SSH key + delta pager integration";

  config = mkIf cfg.enable {
    home-manager.users.stperc = {
      programs.git = {
        signing = {
          key = "/home/stperc/.ssh/id_ed25519";
          signByDefault = true;
        };
        extraConfig = {
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
          core.pager = "delta";
          interactive.diffFilter = "delta --color-only";
          delta = {
            navigate = true;
            line-numbers = true;
            side-by-side = true;
          };
          merge.conflictstyle = "zdiff3";
          diff.colorMoved = "default";
        };
      };

      home.file.".config/git/allowed_signers".text =
        "stperc@users.noreply.github.com ${sshPubKey}\n";
    };
  };
}
