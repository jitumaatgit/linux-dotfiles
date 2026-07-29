{ config, pkgs, ... }:

{
  home.username = "bobbytables";
  home.homeDirectory = "/home/bobbytables";
  home.stateVersion = "25.11";

  # Pervasive editor env vars (non-interactive shells, systemd user units, and
  # direct-spawn processes all inherit these via home-manager's environment.d /
  # hm-session-vars.sh). VISUAL must be a BLOCKING editor subprocess (plain nvim),
  # not a window launcher like `wezterm start -- nvim` — omp's `app.editor.external`
  # spawns $VISUAL and waits on it, and so does any other tool that honors $VISUAL.
  # Interactive zsh still overrides these in home/zsh.nix initContent (last export
  # wins), but its override is kept consistent with nvim too.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  # Per-program modules:
  #   home/zsh.nix       (#3)  — shell + aliases + env + starship            [done]
  #   home/git.nix       (#4)  — git config + SSH signing                    [done]
  #   home/wezterm.nix   (#5)  — terminal                                 [done]
  #   home/nvim.nix      (#6)  — LazyVim                                  [done]
  #   home/niri.nix      (#7)  — compositor (config.kdl)                    [done]
  #   home/waybar.nix    (#7)  — bar (niri module, NOT hyprland)            [done]
  #   home/fuzzel.nix    (#7)  — launcher                                  [done]
  #   home/mako.nix      (#7)  — notifications                             [done]
  #   home/niri-extras.nix (#8)  — swaybg/swayidle/swaylock/polkit/portals/audio/bt/network/fonts [done]
  #   home/packages.nix  (#9)  — CLI tools + languages + btop              [done]
  #   home/ntfy.nix      (#10) — ntfy systemd user service                  [done]
  #   home/opencode.nix  (#11) — opencode config port                        [done]
  imports = [
    ./home/zsh.nix
    ./home/git.nix
    ./home/wezterm.nix
    ./home/nvim.nix
    ./home/niri.nix
    ./home/waybar.nix
    ./home/fuzzel.nix
    ./home/mako.nix
    ./home/niri-extras.nix
    ./home/packages.nix
    ./home/ntfy.nix
    ./home/opencode.nix
    ./home/omp.nix
    ./home/nix-profile-add-fix.nix
  ];
}
