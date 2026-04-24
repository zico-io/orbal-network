{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.orbal.claude;
in
{
  options.orbal.claude = {
    enable = mkEnableOption "Claude Code CLI";

    agentSkills = {
      enable = mkEnableOption "agent-skills-nix integration (bundles skills into ~/.claude/skills)";
      skills = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "skill-creator" "mcp-builder" "claude-api" ];
        description = "Anthropic skill IDs to bundle and sync into the Claude skills dir.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        inputs.claude-code.packages.${pkgs.system}.default
      ];
    }

    (mkIf cfg.agentSkills.enable {
      home-manager.users.stperc = { ... }: {
        imports = [ inputs.agent-skills.homeManagerModules.default ];

        programs.agent-skills = {
          enable = true;
          sources.anthropic = {
            input = "anthropic-skills";
            subdir = "skills";
          };
          sources.orbal = {
            path = ../skills;
            subdir = ".";
          };
          skills.enable = cfg.agentSkills.skills;
          targets.claude.enable = true;
        };
      };
    })
  ]);
}
