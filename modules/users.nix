{ config, pkgs, ... }:

{
  users.users.stperc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "podman" ];
    openssh.authorizedKeys.keys = [
      # TODO: add your SSH public key
      # "ssh-ed25519 AAAA..."
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  home-manager.users.stperc = { pkgs, ... }: {
    home.stateVersion = "25.05";
    programs.git = {
      enable = true;
      userName = "Nico Zamora";
      userEmail = "stperc@users.noreply.github.com";
    };
  };
}
