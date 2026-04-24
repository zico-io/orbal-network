{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbal.tmux;
in
{
  options.orbal.tmux.enable =
    mkEnableOption "tmux config + sessionizer + SSH auto-attach";

  config = mkIf cfg.enable {
    home-manager.users.stperc = {
      programs.zsh.initContent = mkAfter ''
        if [[ -z "$TMUX" && -n "$SSH_TTY" ]] && command -v tmux >/dev/null 2>&1; then
          tmux attach -t main 2>/dev/null || tmux new-session -s main
        fi
      '';

      programs.nushell.loginFile.text = mkAfter ''
        if ('TMUX' not-in $env) and ('SSH_TTY' in $env) and (which tmux | is-not-empty) {
          if (tmux has-session -t=main | complete).exit_code == 0 {
            exec tmux attach -t main
          } else {
            exec tmux new-session -s main
          }
        }
      '';

      programs.tmux = {
        enable = true;
        prefix = "C-a";
        keyMode = "vi";
        mouse = true;
        terminal = "tmux-256color";
        historyLimit = 50000;
        baseIndex = 1;
        escapeTime = 0;
        plugins = with pkgs.tmuxPlugins; [
          sensible
          resurrect
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '15'
            '';
          }
        ];
        extraConfig = ''
          set -ga terminal-overrides ",*256col*:Tc"

          setw -g pane-base-index 1
          set -g renumber-windows on

          bind -r h select-pane -L
          bind -r j select-pane -D
          bind -r k select-pane -U
          bind -r l select-pane -R

          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"
          unbind '"'
          unbind %

          bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded"

          bind -r f display-popup -E -w 60% -h 60% tmux-sessionizer

          set -g status-style "bg=default fg=default"
          set -g status-left  "#[bold]#S #[default]"
          set -g status-right "%H:%M"
          set -g window-status-current-format "#[bold]#I:#W"
          set -g window-status-format         "#I:#W"
        '';
      };

      home.packages = [
        (pkgs.writeShellApplication {
          name = "tmux-sessionizer";
          runtimeInputs = with pkgs; [ tmux fd fzf helix ];
          text = ''
            SEARCH_ROOTS=("$HOME" "$HOME/src")

            if [[ $# -eq 1 ]]; then
              selected=$1
            else
              roots=()
              for root in "''${SEARCH_ROOTS[@]}"; do
                [[ -d "$root" ]] && roots+=("$root")
              done
              if [[ ''${#roots[@]} -eq 0 ]]; then
                exit 1
              fi
              selected=$(
                fd --type d --hidden --max-depth 4 '^\.git$' "''${roots[@]}" --exec dirname {} \; \
                  | sort -u \
                  | fzf
              )
            fi

            if [[ -z "$selected" ]]; then
              exit 0
            fi

            name=$(basename "$selected" | tr '.' '-')

            if ! tmux has-session -t="$name" 2>/dev/null; then
              tmux new-session -ds "$name" -c "$selected" -n edit
              tmux send-keys    -t "$name:edit" "hx ." C-m
              tmux split-window -h -l 40% -t "$name:edit" -c "$selected"
              tmux split-window -v -l 50% -t "$name:edit" -c "$selected"
              tmux select-pane  -t "$name:edit.1"
              tmux new-window   -t "$name:" -n shell -c "$selected"
              tmux select-window -t "$name:edit"
            fi

            if [[ -n "''${TMUX:-}" ]]; then
              tmux switch-client -t "$name"
            else
              tmux attach -t "$name"
            fi
          '';
        })
      ];
    };
  };
}
