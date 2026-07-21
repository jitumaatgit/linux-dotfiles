{ pkgs, ... }:

{
  # User-space CLI tools, language runtimes, and btop config.
  # Source: plan spec §"Programs to Port" + Windows scoop/persist/btop/btop.conf.
  #
  # fzf, zoxide, starship are installed by home/zsh.nix (#3) via their HM
  # modules (programs.fzf / programs.zoxide / programs.starship) — not
  # duplicated here. gh and lazygit have no ported config (binaries only);
  # one-time `gh auth login` is run by the user after first boot.
  #
  # AUR-only items (zen-browser, anki-bin) are NOT in nix — installed via
  # `yay -S zen-browser-bin anki-bin` after the §10 yay bootstrap. Documented
  # in README.md ## Packages.
  home.packages = with pkgs; [
    eza            # ls replacement (zsh alias `ls = eza --icons ...`)
    bat            # cat replacement (zsh alias `cat = bat --paging=never`)
    ripgrep        # grep replacement (zsh alias `grep = rg --color=auto`)
    fd             # find replacement (zsh fzf integration uses fd)
    jq             # JSON processor
    yq-go          # YAML processor (Mike Farah's Go yq — binary is `yq`; matches Scoop)
    yazi           # terminal file manager
    lazygit        # git TUI (zsh alias `lg = lazygit`)
    gh             # GitHub CLI (run `gh auth login --web` once after first boot)
    python3        # Python 3 runtime
    uv             # Python package manager (replaces pip+venv boilerplate)
    nodejs         # Node.js runtime
    rustup         # Rust toolchain manager (run `rustup default stable` post-switch)
    terraform      # IaC
    android-tools  # adb + fastboot (replaces Windows Scoop adb)
  ];

  # btop config ported from Windows scoop/persist/btop/btop.conf.
  # Windows-only (btop4win) options dropped: enable_ohmr (Libre Hardware
  # Monitor DLL), show_gpu / selected_gpu / gpu_mem_override (LHM GPU),
  # rounded_corners (btop4win terminal rendering), cpu_graph_lower = "gpu"
  # (no btop Linux GPU support for Intel Arc integrated). color_theme
  # changed from the Windows absolute path to the bare theme name — btop
  # Linux resolves "tokyo-night" via ~/.config/btop/themes/ then the
  # package's shipped themes/ (nixpkgs btop ships the same upstream themes
  # as btop4win, including tokyo-night). Empty-value options (cpu_sensor,
  # custom_cpu_name, disks_filter, io_graph_speeds, net_iface) omitted so
  # btop's auto-detect defaults apply.
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = false;
      truecolor = true;
      force_tty = true;
      # Box-layout presets (P=alt position, G=graph symbol); whitespace-separated presets cycle with the preset key.
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      vim_keys = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "cpu mem net proc";
      update_ms = 1500;
      proc_sorting = "cpu direct";
      proc_services = false;
      services_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = false;
      proc_per_core = true;
      proc_mem_bytes = true;
      proc_left = false;
      cpu_graph_upper = "total";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      cpu_wide = true;
      show_uptime = true;
      check_temp = true;
      show_coretemp = true;
      temp_scale = "celsius";
      base_10_sizes = false;
      clock_format = "%X";
      background_update = true;
      mem_graphs = true;
      mem_below_net = false;
      show_page = true;
      show_disks = true;
      only_physical = true;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = false;
      show_battery = true;
      log_level = "WARNING";
    };
  };
}
