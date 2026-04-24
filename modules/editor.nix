{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.editor;
in
{
  options.orbal.editor.enable =
    mkEnableOption "helix editor + EDITOR/VISUAL session vars";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.helix ];

    home-manager.users.stperc.home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };
}
