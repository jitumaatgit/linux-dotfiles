{ ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "wezterm";
        font = "JetBrainsMono Nerd Font:size=10";
        lines = 10;
        width = 30;
        horizontal-pad = 8;
        vertical-pad = 4;
        inner-pad = 4;
        prompt = "> ";
        layer = "top";
        icon-theme = "Adwaita";
      };
      colors = {
        background = "1e1e2eff";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        border = "585b70ff";
      };
      border = {
        width = 1;
        radius = 0;
      };
    };
  };
}
