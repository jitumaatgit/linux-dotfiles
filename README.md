# linux-dotfiles

Arch + Nix (standalone Home Manager) + Niri dotfiles for a Dell Latitude 7450 (`archbook`, user `bobbytables`).

## Layout

- `flake.nix` — standalone Home Manager flake, outputs `homeConfigurations.bobbytables`
- `home.nix` — user home entry point; imports per-program modules from `home/*.nix`
- `home/` — per-program modules (zsh, git, wezterm, nvim, niri, ...) added by later tickets
- `INSTALL.md` — full Arch install walkthrough (partitioning, btrfs, systemd-boot, pacman base, services, keyd, zram, pacman snapshot hook)

## Apply

```bash
home-manager switch --flake .#bobbytables
```

## Shell

Login shell is `zsh`, set at user creation time (`useradd -s /usr/bin/zsh bobbytables` — see `INSTALL.md` §3). Home Manager manages the zsh **config** (`.zshrc`, history, completion, plugins, aliases, env, prompt) via `home/zsh.nix`; it does not change the login shell. After the first `home-manager switch`, the interactive shell gets starship prompt, fzf/zoxide integrations, the `occ`/`ocp` opencode helpers, a `snap` btrfs-snapshot helper (pairs with the pacman hook in `INSTALL.md` §7), and the `~/notes/*.env` sourcing loop.

## Git

Git config is managed by `home/git.nix`: identity `Jitu <jitumaat@protonmail.com>`, SSH-signed commits (`gpg.format = ssh`, `user.signingkey = ~/.ssh/id_ed25519`, `commit.gpgsign = true` — no GPG keypair, no gpg-agent), `pull.rebase = true`, `init.defaultBranch = main`, plus the `nvim` difftool and `diffview` mergetool ported from the Windows `.gitconfig`. Windows-only bits (Git Credential Manager `helperselector`, the scoop `includeIf`) are deliberately dropped.

### One-time SSH signing setup

```bash
ssh-keygen -t ed25519 -C "jitumaat@protonmail.com" -f ~/.ssh/id_ed25519
gh auth login --web                       # uploads the public key as an authentication key
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing   # separate upload as a signing key (required for "Verified" badge)
```

`gh auth login` adds the key for git push/pull auth; the `--type signing` upload is a separate step that GitHub needs to verify commit signatures. After `home-manager switch`, every `git commit` is SSH-signed by default.

### Verify

```bash
git commit -S -m test --allow-empty -m 'verify ssh signing'   # -S is default but explicit for clarity
git log --show-signature -1                                    # "Good signature" from ~/.ssh/id_ed25519
```

Push to GitHub and the commit shows a **Verified** badge. If it shows "Unverified", the signing-key upload step was skipped or the wrong key was uploaded — re-run `gh ssh-key add ~/.ssh/id_ed25519.pub --type signing`.

## WezTerm

Terminal is WezTerm, managed by `home/wezterm.nix`. The config is ported verbatim from the Windows `dotfiles/.config/wezterm/` (`wezterm.lua` + `utils.lua`, two files) via `xdg.configFile` — the two-file structure is preserved so `require("utils")` keeps working. `programs.wezterm.enable` installs the package; `extraConfig` is deliberately left unset (it would wrap the script inside a `return { ... }` table body and break the full `config_builder` + `wezterm.on` event-handler style).

Port changes Windows → Linux:
- `default_prog` is `{"zsh", "-l"}` (was the Scoop Git Bash path) — zsh is the user's login shell.
- The `wezterm.home_dir:gsub("\\", "/")` line is dropped (no backslashes on Linux; it only fed the Scoop path).
- Everything else is byte-for-byte: Catppuccin Mocha, leader `Ctrl+Space`, vim-style pane nav (`hjkl`), `Cascadia Code NF` / `JetBrains Mono` font, hyperlink rules, the move-pane `InputSelector`, resize/move key tables.

The `Cascadia Code NF` (Nerd Font) family is required for `eza --icons` glyphs to render. The font package itself is installed by the niri-extras module (#8), not here — WezTerm just references the family name.

## Neovim

Neovim (LazyVim) is managed by `home/nvim.nix`. The full config tree lives at `home/nvim-config/` (69 Lua files: `init.lua` + `lua/config/` + `lua/custom/` + `lua/plugins/` + `ftplugin/`, plus `stylua.toml` + `lazyvim.json`) and is deployed to `~/.config/nvim/` via `xdg.configFile."nvim".source = ./nvim-config; recursive = true`. `recursive = true` makes Home Manager symlink each file individually (via `lndir`) rather than creating a single read-only symlink to the nix store directory — this leaves `~/.config/nvim/` as a real directory that lazy.nvim can write `lazy-lock.json` into on first run. `programs.neovim.enable` installs the `neovim` package; `home.packages = [ pkgs.sqlite ]` declares the libsqlite3 dependency that `sqlite.lua` (yanky's storage backend) loads via `vim.g.sqlite_clib_path`. A 70th Lua file, `lua/_sqlite_path.lua`, is HM-generated at switch time (not in the source tree) so the nix store path of `pkgs.sqlite` can be baked in as the first probe candidate.

Port changes Windows → Linux:
- **`init.lua`**: the Git Bash shell-escaping block (Windows `vim.opt.shell = scoop/.../bash.exe`) is dropped — Linux nvim uses `$SHELL` (zsh) directly. The sqlite DLL path block (`$LOCALAPPDATA/nvim/bin/sqlite3.dll`) is replaced with `require("_sqlite_path")`.
- **`lua/_sqlite_path.lua`** (new, HM-generated): probes `${pkgs.sqlite.out}/lib/libsqlite3.so` (nix store, always present after switch) first, then falls back to `/usr/lib/libsqlite3.so` (Arch), `/usr/lib/x86_64-linux-gnu/libsqlite3.so` (Debian/Ubuntu), `/lib64/libsqlite3.so` (Fedora). First readable wins.
- **`lua/plugins/obsidian.lua`**: `follow_url_func` uses `xdg-open` (was `cmd.exe /c start`).
- **`lua/plugins/markdown-preview.lua`**: `vim.g.mkdp_browser = ""` lets the plugin use `xdg-open` with the system default browser (was a Scoop `zen.exe` shim path).
- **`lua/plugins/snacks.lua`**: the `opts.terminal.shell = "/usr/bin/bash.exe"` override is dropped — snacks.terminal defaults to `$SHELL` (zsh).
- **`lua/plugins/powershell.lua`**: dropped entirely (Windows-only PowerShell Editor Services LSP). The `ftplugin/powershell.lua` is also dropped; the autocmds.lua `VimEnter` powershell execution-policy block is left in place but is guarded by `if vim.fn.has("win32") == 1` so it's a no-op on Linux.
- **Obsidian vault path**: unchanged — the source already uses `vim.fn.expand("~/notes")` which expands to `/home/bobbytables/notes` on Linux. (The stale `C:/Users/student/notes` reference is in the Windows `AGENTS.md` doc only, not in the actual nvim code.)

Not ported (deliberately):
- `bin/sqlite3.dll` — Windows DLL, replaced by nixpkgs `sqlite` (see above).
- `lazy-lock.json` — let lazy.nvim re-resolve plugin versions on Linux.
- `LICENSE`, `README.md` (LazyVim's defaults) — not relevant.
- `lua/plugins/extend-fzf.lua.bak`, `lua/plugins/AGENTS.md`, `lua/custom/obsidian-task-filter/{README.md,config-example.lua}` — not runtime files.

Custom modules ported verbatim: `weekly-note.lua` (`:ObsidianWeekly` / `:ObsidianWeeklyPrev` / `:ObsidianWeeklyNext`), `task-auto-complete.lua` (moves `- [x]` tasks to `## Completed` on `BufWritePost *.md`), `trouble-fetch-fix.lua` (trouble.nvim CPU-leak patch), `obsidian-task-filter/init.lua` (`:ObsidianTasksByTag`).

## Niri

Niri is the Wayland compositor. The `niri` binary itself is system-installed (pacman — see `INSTALL.md` §5) because greetd launches `niri-session` at the display-manager level before any Home Manager generation is active. Everything else — the `config.kdl`, waybar, mako, fuzzel — is HM-managed across four modules: `home/niri.nix`, `home/waybar.nix`, `home/fuzzel.nix`, `home/mako.nix`.

HM release-25.11 has no `programs.niri` module, so `home/niri.nix` writes `~/.config/niri/config.kdl` directly via `xdg.configFile."niri/config.kdl".text = ''...''` (flush-left per the wezterm/nvim convention). Waybar (`programs.waybar.enable` + `settings` + `style`), fuzzel (`programs.fuzzel.enable` + `settings`), and mako (`services.mako.enable` + `settings`) use their HM modules. All three are installed by HM (nixpkgs) — `INSTALL.md` §5 installs only `niri xorg-xwayland` at the pacman level; `waybar mako fuzzel` were removed from the pacman list when #7 landed to avoid double-installation.

### XWayland

XWayland is on-demand and automatic since niri 25.08: if `xorg-xwayland` (or `xwayland-satellite`) is in `$PATH`, niri creates the X11 socket, exports `$DISPLAY`, and spawns XWayland the moment an X11 client connects. No `config.kdl` stanza is needed. `xorg-xwayland` is in the pacman list (`INSTALL.md` §5).

### Keybindings

Mod is **Super**. Full list in `home/niri.nix` and in the plan spec §"Keybindings (Niri `config.kdl`)". Summary:

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (wezterm) |
| `Super+Space` | Launcher (fuzzel) |
| `Super+Q` | Close window |
| `Super+Shift+E` | Quit niri (with confirmation) |
| `Super+F` | Fullscreen window |
| `Super+Esc` | Lock (swaylock) |
| `Super+1`–`Super+9` | Focus workspace N |
| `Super+Shift+1`–`Super+Shift+9` | Move column to workspace N |
| `Super+H` / `Super+L` | Focus column left / right |
| `Super+K` / `Super+J` | Focus window up / down (in column) |
| `Super+Shift+H` / `Super+Shift+L` | Move column left / right |
| `Super+Shift+K` / `Super+Shift+J` | Move window up / down (in column) |
| `Super+Shift+S` | Screenshot (niri built-in, respects `screenshot-path`) |
| `Super+O` | Toggle overview |
| `Super+R` | Cycle preset column widths |
| `Super+Minus` / `Super+Equal` | Column width −10% / +10% |
| FN keys | Volume (`wpctl`) + brightness (`brightnessctl`), `allow-when-locked=true` |

### Bar / launcher / notifications

- **waybar** (`home/waybar.nix`): top bar, catppuccin mocha. Modules: `niri/workspaces` (left), `niri/window` (center), `tray` + `pulseaudio` + `network` + `battery` + `clock` (right). Uses waybar's **niri module** (NOT the hyprland module). Spawned by niri's `spawn-at-startup "waybar"` (HM's `programs.waybar.enable` installs + configures but does NOT create a systemd service by default).
- **fuzzel** (`home/fuzzel.nix`): launcher with `terminal = wezterm`, JetBrainsMono Nerd Font, catppuccin mocha colors. Launched via `Super+Space` from the niri config.
- **mako** (`home/mako.nix`): notifications, anchored top-right, 5s default timeout, catppuccin mocha. Spawned by niri's `spawn-at-startup "mako"` (HM's `services.mako.enable` installs + configures + reloads on change, but does NOT start it as a systemd service).

### Dropped from HyprV4 (deliberately)

wlogout, swappy, thunar, lxappearance, xfce4-settings, sddm (greetd replaces), waybar-hyprland (waybar niri module replaces). None are installed by pacman or HM.

## Spec

Authoritative plan (45 decisions + footguns): [`notes/handoff/arch-nix-niri-plan-2026-07-21.md`](https://github.com/jitumaatgit/dotfiles/blob/main/notes/handoff/arch-nix-niri-plan-2026-07-21.md) — lives in the private `notes` repo; see the handoff doc at `notes/handoff/arch-nix-niri-tickets-2026-07-21.md` for the ticket frontier.
