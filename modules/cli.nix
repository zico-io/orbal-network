{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.cli;
in
{
  options.orbal.cli.enable =
    mkEnableOption "modern CLI replacements (bat, eza, btop, atuin, zoxide, lazygit, gh, jq, yq, …)";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dust
      duf
      procs
      jq
      yq-go
      xh
      dogdns
      just
      watchexec
      hyperfine
      tealdeer
      delta
      slides
    ];

    home-manager.users.stperc = {
      programs.zsh.shellAliases = {
        cat = "bat";
        top = "btop";
        htop = "btop";
        du = "dust";
        df = "duf";
        ps = "procs";
        dig = "dog";
        http = "xh";
        ls = "eza";
        ll = "eza -l --git";
        la = "eza -la --git";
        lt = "eza --tree";
      };

      programs.nushell.shellAliases = {
        # ls/ps/du/http are nushell built-ins with structured output — don't shadow them.
        cat = "bat";
        top = "btop";
        htop = "btop";
        df = "duf";
        dig = "dog";
        ll = "eza -l --git";
        la = "eza -la --git";
        lt = "eza --tree";
      };

      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        options = [ "--cmd cd" ];
      };

      programs.eza = {
        enable = true;
        git = true;
      };

      programs.bat.enable = true;
      programs.btop.enable = true;
      programs.lazygit.enable = true;

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };
    };
  };
}
