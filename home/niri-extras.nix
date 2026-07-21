{ pkgs, ... }:

{
  # Niri supporting stack — wallpaper, screenshots, lock, idle, polkit,
  # portals, audio, bluetooth, network, fonts. Binaries that need system-level
  # config (PAM, systemd system units, /etc, dbus) stay pacman-installed per
  # the plan spec; pure user-space tools move to HM (matching the #7 pattern
  # for waybar/mako/fuzzel).
  #
  # Fonts stay at pacman level (plan spec "base fonts") — HM modules just
  # reference the family names (wezterm/fuzzel/mako/waybar).
  #
  # Catppuccin Mocha palette hardcoded here too (same hex values as
  # niri.nix/waybar.nix/fuzzel.nix/mako.nix) — see #7 handoff for the
  # "no shared palette.nix" rationale.

  # Pure user-space tools, no system-level config — HM-installed.
  # Removed from INSTALL.md §5 pacman list to avoid double-installation.
  home.packages = with pkgs; [
    grim           # screenshot capture
    slurp          # region picker (feeds `grim -g "$(slurp)"`)
    wl-clipboard   # wl-copy / wl-paste (Wayland clipboard for the screenshot binding)
    brightnessctl  # backlight control (FN keys in niri.nix)
    pavucontrol    # audio mixer (NOT pwvucontrol — per plan spec footgun)
    swaybg         # wallpaper (solid color default; swap `-c` for `-i /path/to/img`)
    swayidle       # idle manager (lock + power-off-monitors on timeout; spawned by niri)
  ];

  # swaylock appearance. `package = null` because the pacman-installed swaylock
  # has PAM config in /etc/pam.d/swaylock (HM can't manage that on non-NixOS);
  # the HM module writes ~/.config/swaylock/config (colors/font/indicator only).
  # See HM programs.swaylock module docs — "On non-NixOS, set package to null".
  programs.swaylock = {
    enable = true;
    package = null;
    settings = {
      font = "JetBrainsMono Nerd Font";
      font-size = 14;
      indicator-radius = 100;
      indicator-thickness = 10;
      color = "#1e1e2e";              # base (background)
      inside-color = "#1e1e2e";       # base
      inside-clear-color = "#1e1e2e"; # base
      inside-ver-color = "#89b4fa";   # blue (verifying)
      inside-wrong-color = "#f38ba8"; # red (wrong password)
      ring-color = "#585b70";         # surface
      ring-clear-color = "#f9e2af";   # yellow
      ring-ver-color = "#89b4fa";     # blue
      ring-wrong-color = "#f38ba8";   # red
      key-hl-color = "#89b4fa";       # blue
      bs-hl-color = "#f38ba8";        # red
      line-color = "#00000000";       # transparent (border between inside/ring)
      text-color = "#cdd6f4";         # text
      text-clear-color = "#cdd6f4";
      text-ver-color = "#1e1e2e";     # base (text on blue inside)
      text-wrong-color = "#1e1e2e";   # base (text on red inside)
      show-failed-attempts = true;
      ignore-empty-password = true;
    };
  };
}
