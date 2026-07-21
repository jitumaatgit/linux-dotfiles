{ config, pkgs, ... }:

{
  home.username = "bobbytables";
  home.homeDirectory = "/home/bobbytables";
  home.stateVersion = "25.11";

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
  ];
}
