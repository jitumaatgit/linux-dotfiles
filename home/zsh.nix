{ config, ... }:

let
  fdFiles = "fd --type f --strip-cwd-prefix";
in {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    shellAliases = {
      ls = "eza --icons --group-directories-first -a";
      cat = "bat --paging=never";
      grep = "rg --color=auto";
      lg = "lazygit";
      i = "z -i";
      zi = "z -i";
      vim = "nvim";
      oc = "opencode";
      preview = "bat --style=plain --paging=always";
    };

    initExtra = ''
      setopt auto_cd correct hist_reduce_blanks

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-Z}'

      set_win_title() { echo -ne "\033]0;$(basename "$PWD")\007" }
      starship_precmd_user_func="set_win_title"

      snap() {
        local ts=$(date +%Y%m%d-%H%M%S)
        sudo btrfs subvolume snapshot -r / /.snapshots/snap-"$ts"
      }

      occ() {
        if [ $# -gt 0 ]; then
          opencode run "$@"
          return
        fi
        opencode run --command commit
      }

      ocp() {
        if [ $# -gt 0 ]; then
          opencode --prompt "$*"
          return
        fi
        mkdir -p ~/notes/90-archive/prompts
        local f="$HOME/notes/90-archive/prompts/$(date +%Y%m%d-%H%M%S).md"
        ''${EDITOR:-nvim} "$f"
        [ -s "$f" ] || return
        local p="$(command awk 'NR==1 && /^---$/{f=1; next} f && /^---$/{f=0; next} !f' "$f")"
        [ -n "$p" ] || return
        opencode --prompt "$p"
      }

      export EDITOR="nvim"
      export VISUAL="wezterm start -- nvim"
      export OPENCODE_DISABLE_AUTOUPDATE=true
      export PLANNOTATOR_DATA_DIR="$HOME/notes/docs/plannotator"
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      export MANROFFOPT="-c"
      export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
      export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
      export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

      for f in ~/notes/*.env(N); do [ -f "$f" ] && . "$f"; done
      unset f
    '';
  };

  # Target of RIPGREP_CONFIG_PATH (exported above) — ripgrep errors out if this
  # file is missing, so keep it managed alongside the export. Content mirrors the
  # tablet's ~/.ripgreprc (see notes repo, cross-port-2026-07-18 handoff §4).
  home.file.".ripgreprc".text = ''
    --smart-case
    # Suggestions (uncomment to enable):
    # --hidden
    # --glob=!.git/*
  '';

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" "--info=inline" ];
    defaultCommand = fdFiles;
    fileWidgetCommand = fdFiles;
    changeDirWidgetCommand = "fd --type d --strip-cwd-prefix";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      format = "$directory$git_branch$git_status$character";
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch.format = "on [$branch]($style) ";
      git_status.format = "([$all_status$ahead_behind]($style) )";
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };
    };
  };
}
