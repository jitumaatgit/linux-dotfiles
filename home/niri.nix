{ ... }:

{
  # Niri compositor config.
  # The niri binary is system-installed (pacman) — see INSTALL.md §5.
  # HM release-25.11 has no programs.niri module, so config.kdl is managed
  # directly via xdg.configFile. XWayland is automatic since niri 25.08 when
  # xorg-xwayland (or xwayland-satellite) is in PATH — no config needed here.
  # Content is flush-left (column 0) with closing '' at column 0, matching
  # the wezterm/nvim convention (see #5/#6 handoffs).
  xdg.configFile."niri/config.kdl".text = ''
// Niri config — managed by Home Manager (home/niri.nix).
// Reference: https://github.com/YaLTeR/niri (default config + wiki).
// Mod = Super (niri default on TTY).

input {
    keyboard {
        xkb {
            // layout comes from localectl (en_US.UTF-8)
        }
        numlock
    }

    touchpad {
        tap
        natural-scroll
    }

    warp-mouse-to-focus
    focus-follows-mouse max-scroll-amount="0%"
}

layout {
    gaps 16
    center-focused-column "never"
    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }
    default-column-width { proportion 0.5; }
    focus-ring {
        width 4
        active-color "#7fc8ff"
        inactive-color "#505050"
    }
    border {
        off
    }
}

// waybar + mako are spawned here (HM programs.waybar.enable / services.mako.enable
// install + configure but do NOT create systemd services by default — see #7
// handoff). Same spawn-at-startup pattern for the #8 supporting stack:
//   swaybg        — solid catppuccin base color; swap `-c "#1e1e2e"` for
//                   `-i /path/to/wallpaper.jpg -m fill` to use an image.
//   swayidle      — 300s idle → `swaylock -f`; 301s → power off monitors
//                   (1s after lock so the lock screen is drawn first);
//                   `before-sleep` covers lid-close → logind suspend.
//   polkit-gnome  — full path because /usr/lib/polkit-gnome isn't on $PATH.
//   blueman-applet, nm-applet — tray applets (waybar provides the tray).
// All pacman-installed (PAM/systemd/dbus needs) except swaybg+swayidle which
// HM installs (home/niri-extras.nix). The simpler spawn-at-startup approach
// avoids requiring niri's systemd integration — see #7 handoff for the
// spawn-vs-systemd rationale.
spawn-at-startup "waybar"
spawn-at-startup "mako"
spawn-at-startup "swaybg" "-c" "#1e1e2e" "-m" "fill"
spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "timeout" "301" "niri msg action power-off-monitors" "before-sleep" "swaylock -f"
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "blueman-applet"
spawn-at-startup "nm-applet"

hotkey-overlay {
    skip-at-startup
}

prefer-no-csd

// Work around WezTerm's initial configure bug (empty default-column-width).
window-rule {
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}

binds {
    // Overlay order = config order. Titles are Pango markup: first entry of
    // each group carries a heading line (+ leading blank line as group spacer);
    // category prefixes use Catppuccin Mocha accents. Merged siblings use
    // hotkey-overlay-title=null so they don't reappear unpaired. Media and
    // screenshot binds are hidden from the overlay entirely (title=null).

    // Session
    Mod+Shift+Slash hotkey-overlay-title="<span weight=\"bold\" foreground=\"#f38ba8\" letter_spacing=\"1536\">SESSION</span>\nImportant Hotkeys (this popup)" { show-hotkey-overlay; }
    Mod+Escape  hotkey-overlay-title="<span foreground=\"#f38ba8\">Session:</span> Lock Screen (swaylock)" { spawn "swaylock"; }
    Mod+Shift+E hotkey-overlay-title="<span foreground=\"#f38ba8\">Session:</span> Exit niri" { quit; }
    Mod+Shift+Escape hotkey-overlay-title="<span foreground=\"#f38ba8\">Session:</span> Inhibit Keys (VM passthrough)" { toggle-keyboard-shortcuts-inhibit; }

    // Launch
    Mod+Return hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#a6e3a1\" letter_spacing=\"1536\">LAUNCH</span>\nTerminal (wezterm)" { spawn "wezterm"; }
    Mod+Space  hotkey-overlay-title="<span foreground=\"#a6e3a1\">Launch:</span> App Launcher (fuzzel)" { spawn "fuzzel"; }

    // Focus (columns = H/L, workspaces = K/J, in-column windows = Up/Down)
    Mod+H hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#89b4fa\" letter_spacing=\"1536\">FOCUS</span>\nColumn Left/Right (H/L)" { focus-column-left; }
    Mod+L hotkey-overlay-title=null { focus-column-right; }
    Mod+J hotkey-overlay-title="<span foreground=\"#89b4fa\">Focus:</span> Workspace Down/Up (J/K)" { focus-workspace-down; }
    Mod+K hotkey-overlay-title=null { focus-workspace-up; }
    Mod+Up   hotkey-overlay-title="<span foreground=\"#89b4fa\">Focus:</span> Window Up/Down (arrows)" { focus-window-up; }
    Mod+Down { focus-window-down; }
    Mod+Home hotkey-overlay-title="<span foreground=\"#89b4fa\">Focus:</span> First/Last Column (Home/End)" { focus-column-first; }
    Mod+End  { focus-column-last; }
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+1 hotkey-overlay-title="<span foreground=\"#89b4fa\">Focus:</span> Workspace 1-9" { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    // Move (Shift = within workspace, Ctrl = across workspaces)
    Mod+Shift+H hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#cba6f7\" letter_spacing=\"1536\">MOVE</span>\nColumn Left/Right (Shift+H/L)" { move-column-left; }
    Mod+Shift+L hotkey-overlay-title=null { move-column-right; }
    Mod+Shift+K hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Window Up/Down (Shift+K/J)" { move-window-up; }
    Mod+Shift+J { move-window-down; }
    Mod+Ctrl+Home hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Column to First/Last (Ctrl+Home/End)" { move-column-to-first; }
    Mod+Ctrl+End  { move-column-to-last; }
    Mod+Ctrl+J hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Column to Workspace Down/Up (Ctrl+J/K)" { move-column-to-workspace-down; }
    Mod+Ctrl+K hotkey-overlay-title=null { move-column-to-workspace-up; }
    Mod+Shift+1 hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Column to Workspace 1-9 (Shift+1-9)" { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }
    Mod+Shift+6 { move-column-to-workspace 6; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }
    Mod+Shift+Page_Up   hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Workspace Up/Down, reorder (Shift+PgUp/PgDn)" { move-workspace-up; }
    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+bracketleft  hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Consume or Expel Window ([ / ])" { consume-or-expel-window-left; }
    Mod+bracketright hotkey-overlay-title=null { consume-or-expel-window-right; }
    Mod+Comma  hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Consume Window Into Column" { consume-window-into-column; }
    Mod+Period hotkey-overlay-title="<span foreground=\"#cba6f7\">Move:</span> Expel Window From Column" { expel-window-from-column; }

    // Window
    Mod+Q hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#fab387\" letter_spacing=\"1536\">WINDOW</span>\nClose" { close-window; }
    Mod+F hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Fullscreen" { fullscreen-window; }
    Mod+M hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Maximize Column" { maximize-column; }
    Mod+Ctrl+F hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Expand to Available Width" { expand-column-to-available-width; }
    Mod+W hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Tabbed Column Display" { toggle-column-tabbed-display; }
    Mod+V hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Toggle Floating" { toggle-window-floating; }
    Mod+Shift+V hotkey-overlay-title="<span foreground=\"#fab387\">Window:</span> Focus Floating vs Tiling" { switch-focus-between-floating-and-tiling; }

    // Layout (widths, heights, centering)
    Mod+R hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#f9e2af\" letter_spacing=\"1536\">LAYOUT</span>\nPreset Widths (Shift+R = reverse)" { switch-preset-column-width; }
    Mod+Shift+R { switch-preset-column-width-back; }
    Mod+Minus hotkey-overlay-title="<span foreground=\"#f9e2af\">Layout:</span> Column Width -/+10% (- /=)" { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }
    Mod+Shift+Minus hotkey-overlay-title="<span foreground=\"#f9e2af\">Layout:</span> Window Height -/+10% (Shift+- /=)" { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }
    Mod+Ctrl+R hotkey-overlay-title="<span foreground=\"#f9e2af\">Layout:</span> Reset Window Height" { reset-window-height; }
    Mod+C hotkey-overlay-title="<span foreground=\"#f9e2af\">Layout:</span> Center Column / All Visible (C / Ctrl+C)" { center-column; }
    Mod+Ctrl+C { center-visible-columns; }

    // Monitor (arrow layer, niri defaults)
    Mod+Shift+Left  hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#94e2d5\" letter_spacing=\"1536\">MONITOR</span>\nFocus (Shift+arrows)" { focus-monitor-left; }
    Mod+Shift+Down  { focus-monitor-down; }
    Mod+Shift+Up    { focus-monitor-up; }
    Mod+Shift+Right { focus-monitor-right; }
    Mod+Shift+Ctrl+Left  hotkey-overlay-title="<span foreground=\"#94e2d5\">Monitor:</span> Move Column (Shift+Ctrl+arrows)" { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

    // View
    Mod+O hotkey-overlay-title="\n<span weight=\"bold\" foreground=\"#89dceb\" letter_spacing=\"1536\">VIEW</span>\nToggle Overview" { toggle-overview; }

    // Screenshot — grim+slurp, clipboard-only (per #8 issue). swappy
    // deliberately NOT installed (plan spec). Alternative: niri's built-in
    // `screenshot` action saves to file too (would need `screenshot-path`
    // set + `~/Pictures/Screenshots/` to exist) — see #7 handoff.
    // `\"$(slurp)\"` is KDL-escaped `"`; the shell expands `$(slurp)` to the
    // selected region. grim+slurp+wl-clipboard are HM-installed (niri-extras).
    // Hidden from the hotkey overlay (title=null).
    Mod+Shift+S hotkey-overlay-title=null { spawn-sh "grim -g \"$(slurp)\" - | wl-copy"; }

    // Media — volume (wireplumber wpctl) + brightness (brightnessctl) FN keys.
    // The plan says "FN keys (no extra config)" — niri has NO default
    // keybindings, so the XF86 keys must be bound explicitly or the laptop's
    // volume/brightness FN keys do nothing. wpctl is pacman-installed (pipewire
    // stack, INSTALL.md §5); brightnessctl is HM-installed (niri-extras.nix);
    // swaylock is pacman-installed (PAM config, HM programs.swaylock package=null).
    // Hidden from the hotkey overlay (title=null).
    XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title=null { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
    XF86AudioLowerVolume allow-when-locked=true hotkey-overlay-title=null { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioMute        allow-when-locked=true hotkey-overlay-title=null { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86MonBrightnessUp   allow-when-locked=true hotkey-overlay-title=null { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true hotkey-overlay-title=null { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

    // Mouse wheel (niri defaults) — intentionally untitled and LAST, so the
    // popup shows the keyboard combos above instead of wheel entries.
    Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }
    Mod+WheelScrollLeft  { focus-column-left; }
    Mod+WheelScrollRight { focus-column-right; }
    Mod+Ctrl+WheelScrollLeft  { move-column-left; }
    Mod+Ctrl+WheelScrollRight { move-column-right; }
    Mod+Shift+WheelScrollUp   { focus-column-left; }
    Mod+Shift+WheelScrollDown { focus-column-right; }
    Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
}
'';
}
