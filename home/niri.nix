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
    Mod+Shift+Slash { show-hotkey-overlay; }

    // Launch
    Mod+Return hotkey-overlay-title="Terminal: wezterm" { spawn "wezterm"; }
    Mod+Space  hotkey-overlay-title="Launcher: fuzzel"  { spawn "fuzzel"; }
    Mod+Shift+E { quit; }
    Mod+Escape  hotkey-overlay-title="Lock: swaylock"   { spawn "swaylock"; }

    // Window
    Mod+Q { close-window; }
    Mod+F { fullscreen-window; }

    // Focus (columns = H/L, workspaces = K/J, in-column windows = Up/Down)
    Mod+H { focus-column-left; }
    Mod+L { focus-column-right; }
    Mod+K { focus-workspace-up; }
    Mod+J { focus-workspace-down; }
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up    { focus-window-up; }
    Mod+Down  { focus-window-down; }
    Mod+Home  { focus-column-first; }
    Mod+End   { focus-column-last; }

    // Move (column = H/L, in-column window = K/J)
    Mod+Shift+H { move-column-left; }
    Mod+Shift+L { move-column-right; }
    Mod+Shift+K { move-window-up; }
    Mod+Shift+J { move-window-down; }
    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End  { move-column-to-last; }

    // Move column across workspaces (Ctrl tier); reorder workspaces
    Mod+Ctrl+K { move-column-to-workspace-up; }
    Mod+Ctrl+J { move-column-to-workspace-down; }
    Mod+Shift+Page_Up   { move-workspace-up; }
    Mod+Shift+Page_Down { move-workspace-down; }

    // Consume/expel windows across columns (niri default binds)
    Mod+bracketleft  { consume-or-expel-window-left; }
    Mod+bracketright { consume-or-expel-window-right; }
    Mod+Comma  { consume-window-into-column; }
    Mod+Period { expel-window-from-column; }

    // Column sizing, centering, tabbed display, floating
    Mod+M { maximize-column; }
    Mod+Ctrl+F { expand-column-to-available-width; }
    Mod+C { center-column; }
    Mod+Ctrl+C { center-visible-columns; }
    Mod+W { toggle-column-tabbed-display; }
    Mod+Shift+R { switch-preset-column-width-back; }
    Mod+Ctrl+R { reset-window-height; }
    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }
    Mod+V { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    // Multi-monitor (arrow layer, niri defaults)
    Mod+Shift+Left  { focus-monitor-left; }
    Mod+Shift+Down  { focus-monitor-down; }
    Mod+Shift+Up    { focus-monitor-up; }
    Mod+Shift+Right { focus-monitor-right; }
    Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

    // Mouse wheel (niri defaults)
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

    // Let VMs/remote desktops grab all keys (Escape alone = swaylock)
    Mod+Shift+Escape { toggle-keyboard-shortcuts-inhibit; }

    // Workspaces 1-9
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    // Move column to workspace 1-9 (single-window column = move window)
    Mod+Shift+1 { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }
    Mod+Shift+6 { move-column-to-workspace 6; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }

    // Overview + column width
    Mod+O { toggle-overview; }
    Mod+R { switch-preset-column-width; }
    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }

    // Screenshot — grim+slurp, clipboard-only (per #8 issue). swappy
    // deliberately NOT installed (plan spec). Alternative: niri's built-in
    // `screenshot` action saves to file too (would need `screenshot-path`
    // set + `~/Pictures/Screenshots/` to exist) — see #7 handoff.
    // `\"$(slurp)\"` is KDL-escaped `"`; the shell expands `$(slurp)` to the
    // selected region. grim+slurp+wl-clipboard are HM-installed (niri-extras).
    Mod+Shift+S { spawn-sh "grim -g \"$(slurp)\" - | wl-copy"; }

    // Volume (wireplumber wpctl) + brightness (brightnessctl) — FN keys.
    // The plan says "FN keys (no extra config)" — niri has NO default
    // keybindings, so the XF86 keys must be bound explicitly or the laptop's
    // volume/brightness FN keys do nothing. wpctl is pacman-installed (pipewire
    // stack, INSTALL.md §5); brightnessctl is HM-installed (niri-extras.nix);
    // swaylock is pacman-installed (PAM config, HM programs.swaylock package=null).
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
}
'';
}
