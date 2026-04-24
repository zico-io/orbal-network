{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.shell;
in
{
  options.orbal.shell.enable =
    mkEnableOption "interactive shell environment (zsh + nushell + direnv + base unix tools)";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      direnv
      nix-direnv
      gcc
      gnumake
      ripgrep
      fd
      fzf
      unzip
      pure-prompt
    ];

    programs.direnv.enable = true;
    programs.nix-ld.enable = true;

    environment.shells = [ pkgs.nushell ];

    home-manager.users.stperc = {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        history = {
          size = 50000;
          save = 50000;
          ignoreDups = true;
          ignoreSpace = true;
        };
        initContent = ''
          [ -r /run/secrets/github_token ] && export GITHUB_TOKEN="$(cat /run/secrets/github_token)"
          autoload -U promptinit && promptinit
          prompt pure
        '';
      };

      programs.nushell = {
        enable = true;
        envFile.text = ''
          if ('/run/secrets/github_token' | path exists) {
            $env.GITHUB_TOKEN = (open --raw /run/secrets/github_token | str trim)
          }
        '';
      };

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };

      home.packages = [
        (pkgs.writeShellApplication {
          name = "rebuild";
          text = ''
            action="''${1:-switch}"
            host="''${2:-$HOSTNAME}"

            flake=""
            dir="$PWD"
            while [[ "$dir" != "/" ]]; do
              if [[ -f "$dir/flake.nix" ]]; then
                flake="$dir"
                break
              fi
              dir="$(dirname "$dir")"
            done
            flake="''${flake:-$HOME/orbal-network}"

            if [[ ! -f "$flake/flake.nix" ]]; then
              echo "rebuild: no flake.nix in \$PWD ancestors or \$HOME/orbal-network" >&2
              exit 1
            fi

            echo "→ sudo nixos-rebuild $action --flake $flake#$host"
            exec sudo nixos-rebuild "$action" --flake "$flake#$host"
          '';
        })
      ];
    };
  };
}
