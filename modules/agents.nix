{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.orbal.agents;
in
{
  options.orbal.agents = {
    claude.enable = mkEnableOption "Claude Code CLI";

    anyEnabled = mkOption {
      type = types.bool;
      default = cfg.claude.enable;
      description = ''
        Derived: true if any agent is enabled. Other modules read this to
        gate skill contributions. Future agents should OR into the default.
      '';
    };

    skills = {
      enable = mkOption {
        type = types.bool;
        default = cfg.anyEnabled;
        description = "Sync bundled agent skills. Defaults on when any agent is enabled.";
      };
      list = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Skill IDs to bundle into the agent skills dir. Modules append their
          bundled skills here; hosts may append per-host extras.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.claude.enable {
      environment.systemPackages = [
        inputs.claude-code.packages.${pkgs.system}.default
      ];
    })

    (mkIf cfg.anyEnabled {
      orbal.agents.skills.list = [
        "skill-creator"
        "onboard-host"
        "skill-review"
        "skill-optimize"
      ];
    })

    (mkIf cfg.skills.enable {
      home-manager.users.stperc = { ... }: {
        imports = [ inputs.agent-skills.homeManagerModules.default ];

        programs.agent-skills = {
          enable = true;
          sources.anthropic = {
            input = "anthropic-skills";
            subdir = "skills";
          };
          sources.orbal = {
            path = ../.mex/skills;
            subdir = ".";
          };
          skills.enable = cfg.skills.list;
          targets.claude.enable = cfg.claude.enable;
        };
      };
    })
  ];
}
