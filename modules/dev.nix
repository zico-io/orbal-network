{ config, lib, ... }:

# Meta-module. `orbal.dev.enable = true` opts into the common dev bundle:
# interactive shell, modern CLI tools, git signing, tmux, helix, and sops
# secrets. Language toolchains (orbal.languages.*) and Claude
# (orbal.claude.*) remain independent — enable them per-host as needed.

with lib;

let
  cfg = config.orbal.dev;
in
{
  options.orbal.dev.enable =
    mkEnableOption "dev bundle (shell + cli + git + tmux + editor + secrets)";

  config = mkMerge [
    (mkIf cfg.enable {
      orbal.secrets.enable = mkDefault true;
      orbal.shell.enable = mkDefault true;
      orbal.cli.enable = mkDefault true;
      orbal.git.enable = mkDefault true;
      orbal.tmux.enable = mkDefault true;
      orbal.editor.enable = mkDefault true;
    })

    (mkIf (cfg.enable && config.orbal.agents.anyEnabled) {
      orbal.agents.skills.list = [ "commit-smart" ];
    })
  ];
}
