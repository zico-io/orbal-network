{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./disk-config.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "nodev" ];
  };

  boot.swraid = {
    enable = true;
    mdadmConf = "MAILADDR root";
  };

  networking = {
    useDHCP = false;
    interfaces.enp5s0 = {
      ipv4.addresses = [{
        address = "46.62.190.233";
        prefixLength = 32;
      }];
      ipv6.addresses = [{
        address = "2a01:4f9:3090:1e4a::2";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "46.62.190.193";
      interface = "enp5s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp5s0";
    };
    nameservers = [ "185.12.64.1" "185.12.64.2" "2a01:4ff:ff00::add:1" ];
    firewall.allowedTCPPorts = [ 22 ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
