{ config, pkgs, ... }:

{
  home.username = "bobbytables";
  home.homeDirectory = "/home/bobbytables";
  home.stateVersion = "25.11";

  # Per-program modules:
  #   home/zsh.nix       (#3)  — shell + aliases + env + starship            [done]
  #   home/git.nix       (#4)  — git config + SSH signing
  #   home/wezterm.nix   (#5)  — terminal
  #   home/nvim.nix      (#6)  — LazyVim
  #   home/niri.nix      (#7)  — compositor + waybar + fuzzel + mako
  #   home/niri-extras.nix (#8) — wallpaper, screenshots, lock, polkit, portals, audio, bluetooth, network, fonts
  #   home/packages.nix  (#9)  — CLI tools + languages + btop
  #   home/ntfy.nix      (#10) — ntfy systemd user service
  #   home/opencode.nix  (#11) — opencode config port
  imports = [
    ./home/zsh.nix
  ];
}
