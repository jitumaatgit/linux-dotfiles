{ ... }:

{
  programs.waybar = {
    enable = true;

    # Top bar: niri workspaces left, focused window center, status right.
    # Uses waybar's niri module (niri/workspaces + niri/window) — NOT the
    # hyprland module. Module names with slashes are quoted Nix attrs.
    settings = [{
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;

      modules-left = [ "niri/workspaces" ];
      modules-center = [ "niri/window" ];
      modules-right = [ "tray" "pulseaudio" "network" "battery" "clock" ];

      "niri/workspaces" = {
        format = "{index}";
      };

      "niri/window" = {
        format = "{}";
      };

      tray = {
        spacing = 10;
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "VOL muted";
        on-click = "pavucontrol";
      };

      network = {
        format-wifi = "{essid} {signalStrength}%";
        format-disconnected = "Disconnected";
        tooltip-format = "{ifname} {ipaddr}";
      };

      battery = {
        format = "BAT {capacity}%";
        states = {
          warning = 30;
          critical = 15;
        };
      };

      clock = {
        format = "{:%H:%M %a %Y-%m-%d}";
        tooltip-format = "{:%A %B %d %Y}";
      };
    }];

    # Catppuccin Mocha to match wezterm. Flush-left per the '' convention.
    style = ''
* {
    font-family: "JetBrainsMono Nerd Font", "JetBrains Mono";
    font-size: 10px;
}

window#waybar {
    background-color: #1e1e2e;
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    color: #cdd6f4;
    background: transparent;
    border: none;
}

#workspaces button.focused {
    color: #89b4fa;
    font-weight: bold;
}

#workspaces button.urgent {
    color: #f38ba8;
}

#window {
    padding: 0 8px;
    color: #cdd6f4;
}

#tray, #pulseaudio, #network, #battery, #clock {
    padding: 0 10px;
    margin: 0 2px;
    color: #cdd6f4;
    background: transparent;
}

#pulseaudio.muted {
    color: #f38ba8;
}

#battery.warning {
    color: #f9e2af;
}

#battery.critical {
    color: #f38ba8;
}

#network.disconnected {
    color: #f38ba8;
}
'';
  };
}
