{
  description = "zebes — NixOS homelab fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, disko, ... }@inputs:
    let
      system = "x86_64-linux";

      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}
          ./modules/base.nix
          ./modules/users.nix
          ./modules/dev.nix
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            networking.hostName = hostname;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        forge = mkHost "forge";
        seed = mkHost "seed";
        # elitedesk-1 = mkHost "elitedesk-1";
        # elitedesk-2 = mkHost "elitedesk-2";
        # elitedesk-3 = mkHost "elitedesk-3";
      };
    };
}
