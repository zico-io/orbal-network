{
  description = "orbal — NixOS homelab fleet";

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

    claude-code = {
      url = "github:sadjow/claude-code-nix";
    };

    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, disko, claude-code, agent-skills, anthropic-skills, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}
          ./modules/base.nix
          ./modules/users.nix
          ./modules/secrets.nix
          ./modules/shell.nix
          ./modules/cli.nix
          ./modules/git.nix
          ./modules/tmux.nix
          ./modules/editor.nix
          ./modules/languages.nix
          ./modules/agents.nix
          ./modules/local-llm.nix
          ./modules/tailnet-hosts.nix
          ./modules/reverse-proxy.nix
          ./modules/dns-resolver.nix
          ./modules/dev.nix
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
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

      devShells.${system}.bask = pkgs.mkShell {
        packages = with pkgs; [
          bun
          typescript
          typescript-language-server
          pnpm_8
        ];
      };
    };
}
