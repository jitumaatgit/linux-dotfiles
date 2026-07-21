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

// waybar is spawned here (HM programs.waybar.enable installs + configures
// but does NOT create a systemd service by default). mako likewise — HM
// services.mako.enable installs + configures + reloads on change, but does
// NOT start it; niri spawns it.
spawn-at-startup "waybar"
spawn-at-startup "mako"

hotkey-overlay {
    skip-at-startup
}

prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

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

    // Focus (column nav = H/L, in-column nav = K/J)
    Mod+H { focus-column-left; }
    Mod+L { focus-column-right; }
    Mod+K { focus-window-up; }
    Mod+J { focus-window-down; }

    // Move (column = H/L, in-column window = K/J)
    Mod+Shift+H { move-column-left; }
    Mod+Shift+L { move-column-right; }
    Mod+Shift+K { move-window-up; }
    Mod+Shift+J { move-window-down; }

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

    // Screenshot (niri built-in; respects screenshot-path above)
    Mod+Shift+S { screenshot; }

    // Volume (wireplumber wpctl) + brightness (brightnessctl) — FN keys.
    // The plan says "FN keys (no extra config)" — niri has NO default
    // keybindings, so the XF86 keys must be bound explicitly or the laptop's
    // volume/brightness FN keys do nothing. wpctl + brightnessctl are in the
    // pacman list (INSTALL.md §5); swaylock (Super+Esc above) likewise.
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
}
'';
}
