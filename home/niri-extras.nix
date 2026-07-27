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
    # Interactive key-hint panel — built from the which-key-wayland flake input
    # (overlay in flake.nix). Triggered by niri bind `Mod+semicolon`.
    # Config: ~/.config/which-key-wayland/config.kdl (xdg.configFile below).
    # Static cheatsheet overlay — built inline from PyPI sdist (overlay in
    # flake.nix calls home/cheatbind.nix). Triggered by niri bind
    # `Mod+Shift+Slash`. Style: ~/.config/cheatbind/style.css (xdg.configFile
    # below). Both overlay tools install declaratively, no AUR/pipx needed.
    which-key-wayland
    cheatbind
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
  # ── Cheatsheet overlays ─────────────────────────────────────────────────
  # Replaces niri's single-column hotkey-overlay with two purpose-built GTK
  # popups, both built declaratively via HM (overlay in flake.nix):
  #
  #   cheatbind          — styled static cheatsheet. Auto-parses niri's
  #                        config.kdl (plain `hotkey-overlay-title=` labels,
  #                        `//##! Section` headers, `//#!` column breaks,
  #                        `hotkey-overlay-title=null` hides a row). Toggled
  #                        by niri bind `Mod+Shift+Slash { spawn "cheatbind"; }`.
  #
  #   which-key-wayland   — interactive "press a prefix → see continuations"
  #                        panel à la which-key.nvim. Its own KDL config below
  #                        mirrors the niri groups as actions/sub-pages. Triggered
  #                        by `Mod+Semicolon { spawn "which-key-wayland"; }`.
  #
  # Both are color-themed with the hardcoded Catppuccin Mocha palette (see
  # niri.nix/waybar.nix — same hex values, no shared palette.nix per #7). The
  # CSS/KDL are fired at ~/.config/cheatbind/style.css and
  # ~/.config/which-key-wayland/config.kdl respectively.

  # cheatbind overlay appearance — loaded on top of cheatbind's built-in CSS,
  # so only overrides are needed. Class names come from cheatbind's default
  # src/cheatbind/style/cheatsheet.css (overlay, overlay-title, overlay-subtitle,
  # keybinds-grid, column, section, section-title, bind-row, bind-description,
  # key-combos, key, key-wide).
  xdg.configFile."cheatbind/style.css".text = ''
/* cheatbind overlay — Catppuccin Mocha override layer.
   Loaded on top of cheatbind's built-in cheatsheet.css; only overrides here. */

/* Backdrop: deep base with slight transparency so the desktop reads through. */
.overlay {
    background-color: rgba(30, 30, 46, 0.92);   /* base */
}

/* Title + subtitle. */
.overlay-title       { color: #cdd6f4; }        /* text */
.overlay-subtitle    { color: #7f849c; }        /* overlay2 */

/* Section headings — per-group Mocha accents, matching the old Pango titles. */
/* Default (Session) accent is red; per-section overrides follow. */
.section-title {
    color:                #f38ba8;             /* red — default, overridden below */
    border-bottom-color:  rgba(243, 139, 168, 0.25);
}

/* Bind row descriptions + key pills. */
.bind-description { color: #cdd6f4; }           /* text */
.key-alt-separator,
.key-separator    { color: #585b70; }          /* surface2 */

/* Key pill: surface gradient with subtle top-highlight + bottom-shadow, like
   the default but reskinned to Mocha surface tones. */
.key {
    background: linear-gradient(to bottom, #45475a 0%, #313244 100%); /* surface0 → mantle-ish */
    color: #cdd6f4;                              /* text */
    border-top:    1px solid #585b70;            /* surface2 — top highlight */
    border-bottom: 2px solid #11111b;           /* crust — drop shadow */
    border-left:   1px solid #45475a;           /* surface1 */
    border-right:  1px solid #45475a;           /* surface1 */
}
  '';

  # which-key-wayland config — interactive prefix-key panel. KDL format; color
  # block takes "#RGB" / "#RRGGBB" / "#RRGGBBAA". The bind tree below mirrors
  # the niri groups so the cheatbind static sheet and this interactive panel
  # describe the same keyset. Triggered by `Mod+semicolon` in niri.nix.
  xdg.configFile."which-key-wayland/config.kdl".text = ''
// which-key-wayland — interactive key-hint panel (Mocha).
// Trigger: niri bind `Mod+semicolon { spawn "which-key-wayland"; }`.
// Press a prefix key to open a sub-page; Esc goes back / closes.

timeout 3000 // ms; 0 disables auto-hide

font {
  size 15.0
  line-height 19.0
}

color {
  fg-key "#cdd6f4"       // text
  fg-separator "#585b70" // surface2
  fg-action "#89b4fa"     // blue — leaf action
  fg-group "#cba6f7"      // mauve — group (sub-page)
  bg "#1e1e2ee6"          // base + ~90% alpha
}

layout {
  width 520
  max-items 12
  padding 8
  radius 12
  anchor 2 // 1:tr | 2:br | 3:bl | 4:tl
  margin {
    top 12
    right 12
    bottom 12
    left 12
  }
}

bind {
  // ── Direct actions on the root page ──
  Return    desc="Terminal (wezterm)"          { spawn "wezterm"; }
  Space     desc="App launcher (fuzzel)"       { spawn "fuzzel"; }
  O         desc="Toggle overview"             { sh "niri msg action toggle-overview"; }
  Q         desc="Close window"                { sh "niri msg action close-window"; }
  H         desc="Cheatsheet (cheatbind)"      { spawn "cheatbind"; }
  Print     desc="Screenshot region → clip"    { sh "grim -g \"$(slurp)\" - | wl-copy"; }

  // ── Session ──
  s desc="Session" {
    // NOTE: Esc is reserved by which-key-wayland (back/close), so lock stays
    // on its direct niri bind (Mod+Escape) and is NOT mirrored here.
    E desc="Exit niri"            { sh "niri msg action quit"; }
    I desc="Inhibit keys (VM)"    { sh "niri msg action toggle-keyboard-shortcuts-inhibit"; }
  }

  // ── Focus ──
  f desc="Focus" {
    h desc="Column left/right (H/L)"   { sh "niri msg action focus-column-left"; }
    l desc="Column left/right (H/L)"   { sh "niri msg action focus-column-right"; }
    j desc="Workspace down/up (J/K)"   { sh "niri msg action focus-workspace-down"; }
    k desc="Workspace down/up (J/K)"   { sh "niri msg action focus-workspace-up"; }
    n desc="Window up/down (arrows)"   { sh "niri msg action focus-window-up"; }
    p desc="Window up/down (arrows)"   { sh "niri msg action focus-window-down"; }
    Home   desc="First/last column"    { sh "niri msg action focus-column-first"; }
    End    desc="First/last column"    { sh "niri msg action focus-column-last"; }
  }

  // ── Move ──
  m desc="Move" {
    h desc="Column left/right (Shift+H/L)"   { sh "niri msg action move-column-left"; }
    l desc="Column left/right (Shift+H/L)"   { sh "niri msg action move-column-right"; }
    k desc="Window up/down (Shift+K/J)"      { sh "niri msg action move-window-up"; }
    j desc="Window up/down (Shift+K/J)"      { sh "niri msg action move-window-down"; }
    c desc="Consume / expel window ([ / ])" { sh "niri msg action consume-or-expel-window-left"; }
    v desc="Consume / expel window ([ / ])" { sh "niri msg action consume-or-expel-window-right"; }
  }

  // ── Window ──
  w desc="Window" {
    c desc="Close"               { sh "niri msg action close-window"; }
    f desc="Fullscreen"          { sh "niri msg action fullscreen-window"; }
    m desc="Maximize column"     { sh "niri msg action maximize-column"; }
    e desc="Expand to available" { sh "niri msg action expand-column-to-available-width"; }
    t desc="Tabbed column"       { sh "niri msg action toggle-column-tabbed-display"; }
    v desc="Toggle floating"     { sh "niri msg action toggle-window-floating"; }
    V desc="Floating vs tiling"  { sh "niri msg action switch-focus-between-floating-and-tiling"; }
  }
  // ── Layout ──
  l desc="Layout" {
    r desc="Preset widths (R = reverse)" { sh "niri msg action switch-preset-column-width"; }
    R desc="Preset widths (R = reverse)" { sh "niri msg action switch-preset-column-width-back"; }
    c desc="Center column / all visible" { sh "niri msg action center-column"; }
    C desc="Center column / all visible" { sh "niri msg action center-visible-columns"; }
    // Column width ±10% (-/=) is exposed only via the cheatbind static
    // sheet: which-key-wayland can't bind "-" or "=" cleanly as KDL node names.
  }

  // ── Monitor ──
  M desc="Monitor" {
    j desc="Focus (Shift+arrows)"  { sh "niri msg action focus-monitor-down"; }
    k desc="Focus (Shift+arrows)"  { sh "niri msg action focus-monitor-up"; }
    h desc="Focus (Shift+arrows)"  { sh "niri msg action focus-monitor-left"; }
    l desc="Focus (Shift+arrows)"  { sh "niri msg action focus-monitor-right"; }
  }
}
  '';
}
