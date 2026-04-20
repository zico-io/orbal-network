{ config, pkgs, ... }:

{
  users.users.stperc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "podman" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ65MRiriewaqb7UjXy9VCFizBq9V/ZBeloByaLhSV0M dev@zico.xyz"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  home-manager.users.stperc = { pkgs, ... }: {
    home.stateVersion = "25.05";
    programs.git = {
      enable = true;
      userName = "Nicolae";
      userEmail = "stperc@users.noreply.github.com";
    };
  };
}
