{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.zebes.dev;
  sshPubKey = builtins.elemAt config.users.users.stperc.openssh.authorizedKeys.keys 0;
in
{
  options.zebes.dev = {
    enable = mkEnableOption "development environment tools and shell config";

    languages.node.enable = mkEnableOption "Node.js toolchain (nodejs, npm)";
    languages.go.enable = mkEnableOption "Go toolchain (go, gopls)";
    languages.rust.enable = mkEnableOption "Rust toolchain (rustc, cargo, rust-analyzer)";
    languages.python.enable = mkEnableOption "Python toolchain (python3, virtualenv)";
  };

  config = mkIf cfg.enable {

    # Core dev tools
    environment.systemPackages = with pkgs;
      [
        direnv
        nix-direnv
        gcc
        gnumake
        ripgrep
        fd
        unzip
        helix
        pure-prompt
        inputs.claude-code.packages.${pkgs.system}.default
      ]
      ++ optionals cfg.languages.node.enable [ nodejs ]
      ++ optionals cfg.languages.go.enable [ go gopls ]
      ++ optionals cfg.languages.rust.enable [ rustc cargo rust-analyzer ]
      ++ optionals cfg.languages.python.enable [ python3 python3Packages.virtualenv ];

    programs.direnv.enable = true;
    programs.nix-ld.enable = true;

    # sops-nix: decrypt dev secrets from age-encrypted file
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

    # Also register nushell as a valid login shell.
    environment.shells = [ pkgs.nushell ];

    # Home-manager: zsh (pure prompt), nushell, direnv (merges with users.nix)
    home-manager.users.stperc = { pkgs, ... }: {
      programs.git = {
        signing = {
          key = "/home/stperc/.ssh/id_ed25519";
          signByDefault = true;
        };
        extraConfig = {
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
        };
      };

      home.file.".config/git/allowed_signers".text =
        "stperc@users.noreply.github.com ${sshPubKey}\n";

      home.sessionVariables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

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
    };
  };
}
