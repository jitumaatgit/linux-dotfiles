# linux-dotfiles

Arch + Nix (standalone Home Manager) + Niri dotfiles for a Dell Latitude 7450 (`archbook`, user `bobbytables`).

## Layout

- `flake.nix` — standalone Home Manager flake, outputs `homeConfigurations.bobbytables`
- `home.nix` — user home entry point; imports per-program modules from `home/*.nix`
- `home/` — per-program modules (zsh, git, wezterm, nvim, niri, ...) added by later tickets
- `INSTALL.md` — full Arch install walkthrough (partitioning, btrfs, systemd-boot, pacman base, services, keyd, zram, pacman snapshot hook)

## Quickstart

The complete flow from a blank NVMe to a working desktop:

1. **Arch install + system-level config** — follow [`INSTALL.md`](INSTALL.md) end-to-end (partition, btrfs subvolumes, systemd-boot, pacman base, services, keyd, zram, greetd→`niri-session`, Nix + Home Manager standalone). Reboot, log in as `bobbytables` at the tuigreet prompt → drops into niri.
2. **Clone this repo**:
   ```bash
   git clone https://github.com/jitumaatgit/linux-dotfiles.git ~/linux-dotfiles
   cd ~/linux-dotfiles
   ```
3. **Apply the flake** — one transaction replaces the entire user-space config:
   ```bash
   home-manager switch --flake .#bobbytables
   ```
   Exits 0 on success (see §Verify below).
4. **One-time post-switch steps** — these are secrets, SSH keys, external binaries, and private repos that are fundamentally outside any declarative config manager (not user-space config). HM reproduces all user-space config in step 3; these are the irreducible manual leftovers:
   - SSH key + GitHub auth: `ssh-keygen -t ed25519 -C "jitumaat@protonmail.com" -f ~/.ssh/id_ed25519`, then `gh auth login --web` (uploads the key for git auth + auths the `gh` CLI; token lives in `~/.config/gh/hosts.yml`, outside HM scope) + `gh ssh-key add ~/.ssh/id_ed25519.pub --type signing` (separate upload for the "Verified" badge — see §Git).
   - `rustup default stable` — `home/packages.nix` ships `rustup` with no toolchain pinned; this installs `rustc`/`cargo`.
   - `systemctl --user enable --now pipewire pipewire-pulse wireplumber` — pipewire user units are pacman-installed but not enabled per-user (see `INSTALL.md` §6).
   - Clone `~/notes` (private secrets repo) — the zsh `for f in ~/notes/*.env(N)` loop in `home/zsh.nix` sources API keys (`NVIDIA_API_KEY`, etc.) on shell start.
   - `npm i -g opencode` — the opencode binary is NOT installed by HM; only its config files are (see §opencode).
   - `npx skills add -g mattpocock/skills` (or whichever sources) — opencode skills install to `~/.agents/skills/` (user-level), not HM-managed.
5. **Log in to niri** — `niri-session` is already running from the greetd login. `Super+Return` opens WezTerm (zsh + starship prompt); `Super+Space` opens fuzzel.
6. **Verify** — run the commands in §Verify below.

## Verify

Run after `home-manager switch --flake .#bobbytables` to confirm the full stack landed:

```bash
# 1. The switch itself exits 0 (HM prints "Activating createHome" then returns).
home-manager switch --flake .#bobbytables --verbose; echo "exit=$?"

# 2. Niri desktop is up (greetd launched niri-session at login).
niri msg version
pgrep -x niri >/dev/null && echo "niri up" || echo "niri down"

# 3. WezTerm launches with Catppuccin Mocha + Cascadia Code NF (config parses → exits 0).
wezterm show-keys --key-table | head    # leader is Ctrl+Space

# 4. Neovim launches LazyVim (lazy.nvim bootstraps plugins on first run).
nvim --headless "+Lazy! sync" +qa       # one-time plugin install; then `nvim` for real

# 5. CLI tools work (all HM-installed via home/packages.nix + home/zsh.nix).
bat --version && rg --version && eza --version && btop --version

# 6. ntfy subscription service is active (HM started it via wantedBy=default.target).
systemctl --user status ntfy-client --no-pager
ntfy pub --title="test" shift-automator-doomax "hi"   # expect a mako toast

# 7. opencode runs and reads the HM-managed config.
opencode --version
test -n "$NVIDIA_API_KEY" && echo "NVIDIA_API_KEY set" || echo "unset — clone ~/notes"
```

If any step fails, see the per-module sections below for module-specific verify commands and §Gotchas for known footguns.

## Disaster recovery

**Rebootstrap from `linux-dotfiles` is the entire DR plan.** Git is the only backup.

- The btrfs pacman-hook snapshots (`INSTALL.md` §7) cover rollback for system-level pacman transactions — they are NOT off-machine backups.
- All user-space config is declarative in this repo. A fresh clone + `home-manager switch --flake .#bobbytables` reproduces the entire user-space on any Arch + Nix + HM machine.
- `~/notes` (private) is the only other repo needed for a full restore — it holds secrets (`*.env`) and Obsidian notes. Clone it separately.
- NOT in this repo (re-create on a new machine via the §Quickstart post-switch steps): nvim plugin state (`lazy-lock.json`), opencode skills (`~/.agents/skills/`), `~/.config/gh/hosts.yml`, SSH keys, `~/notes`.

Recovery procedure (on a fresh Arch install that has followed `INSTALL.md` through §9):

```bash
git clone https://github.com/jitumaatgit/linux-dotfiles.git ~/linux-dotfiles
cd ~/linux-dotfiles
home-manager switch --flake .#bobbytables
# then the post-switch steps in §Quickstart
```

## Gotchas

Footguns from the plan spec — either resolved in code or documented here so the user/next-agent knows:

- **User is `bobbytables`, not `fomar`/`student`** — `nixos-dotfiles` uses `fomar`; `student` is a stale username from an older Windows machine. This repo uses `bobbytables` everywhere (flake target `.#bobbytables`, `home.username`, ported paths). The `C:/Users/student/...` strings elsewhere in this README are historical "what changed from Windows" notes in the Neovim and btop port sections, not live paths.
- **Nix-on-Arch is NOT NixOS** — no `nixos-rebuild`, no `/etc/nixos/configuration.nix`, no `nixosConfigurations`. The system is Arch (pacman-managed); only user-space is declarative via standalone Home Manager. `homeConfigurations.bobbytables` is the only flake output.
- **Home Manager is standalone, not a NixOS module** — see above. The flake pulls HM as an input for `homeManagerConfiguration`; there is no `nixosConfigurations` output.
- **zsh, not bash** — login shell is zsh (set at `useradd -s` time in `INSTALL.md` §3). Ported from `tablet-dotfiles/.zshrc`, NOT from Windows `.bashrc`. Key changes from the tablet version: `batcat`→`bat`, `foot nvim`→`wezterm start -- nvim`, drop `find='fd'` alias (Arch `fd` is `fd`, not `fdfind`).
- **`occ()` ported from Windows, not tablet** — tablet's `occ()` has bare-repo git-dir switching for `$HOME/.dotfiles`; this repo is a regular clone, so the simpler Windows `occ()` is used (`opencode run "$@"` / `opencode run --command commit`).
- **SSH signing, not GPG** — `gpg.format = ssh`, `user.signingkey = ~/.ssh/id_ed25519`, `commit.gpgsign = true`. No GPG keypair, no gpg-agent. `gh ssh-key add --type signing` is a SEPARATE upload from `gh auth login` (required for the "Verified" badge on GitHub).
- **No nvim-data backup** — the Windows `nvim-data-remote` junction is deliberately not ported. This machine is not ephemeral; lazy.nvim re-resolves plugins on first run (`nvim --headless "+Lazy! sync" +qa`).
- **No mouse-grid tool** — `keynavish` and `warpd` both deliberately dropped. Use the trackpad.
- **Don't remap RWin→LCtrl** — that was a Windows AHK thing. On Linux, Super is Niri's Mod key; keep RWin as Super. keyd only remaps Caps (`overload(control, esc)` — tap=Esc, hold=Ctrl).
- **Mixer is pavucontrol, not pwvucontrol** — `home/niri-extras.nix` installs `pavucontrol` for Bluetooth profile-switching robustness. Do not swap it.
- **No JACK** — `pipewire-jack` deliberately not installed. Only `pipewire-pulse` + `pipewire-alsa`.
- **`discard=async` not `fstrim.timer`** — btrfs mount option in `/etc/fstab` (`INSTALL.md` §1). NVMe-only. Do NOT enable `fstrim.timer` (redundant with async discard).
- **thermald is root, PPD is user toggle** — `thermald` is a root service; `powerprofilesctl` (from `power-profiles-daemon`) is the user-facing 3-mode toggle. Don't try to make thermald user-controllable.
- **No firewall services running by default** — `ufw` is enabled (default deny incoming), but no services listen in the base install. If `sshd` is ever installed, ufw already covers it.
- **Plannotator CLI is cross-platform** — not Windows-only. Re-run the install script on Linux (see Plannotator docs); `PLANNOTATOR_DATA_DIR="$HOME/notes/docs/plannotator"` is set by `home/zsh.nix`.
- **HM flake target is `.#bobbytables`, hostname is `archbook`** — don't conflate. `home-manager switch --flake .#bobbytables` is the command; `archbook` is `/etc/hostname` and mDNS name.
- **Flush-left `''...''` strings** — Nix indented-string stripping: the closing `''` at column 0 means 0 leading spaces are stripped from each line. All `xdg.configFile` text blocks in `home/*.nix` follow this convention (wezterm/nvim/niri/waybar/ntfy/opencode). Reindenting the Lua/KDL/TOML/JSON inside the `''...''` to match the Nix nesting will strip 0 spaces and the generated file will retain the original indentation; reindenting AND moving the closing `''` will change what gets stripped. The only `${` in these blocks is the intentional Nix interpolation; a literal `${` in the content must be escaped as `''${`.

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
| `Super+Shift+S` | Screenshot (`grim -g "$(slurp)" \| wl-copy`, clipboard-only) |
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

## Niri Extras

The supporting desktop stack (wallpaper, screenshots, lock, idle, polkit, portals, audio, bluetooth, network, fonts) is split across HM and pacman, managed by `home/niri-extras.nix` plus `spawn-at-startup` lines in `home/niri.nix`.

### HM-installed (pure user-space tools, no system config)

`grim`, `slurp`, `wl-clipboard`, `brightnessctl`, `pavucontrol`, `swaybg`, `swayidle` — declared in `home/niri-extras.nix` `home.packages`. Removed from `INSTALL.md` §5 pacman list to avoid double-installation (same pattern as #7's waybar/mako/fuzzel).

### pacman-installed (system-level config needed, no HM equivalent)

- **swaylock** — PAM config in `/etc/pam.d/swaylock` (HM can't manage that on non-NixOS). `home/niri-extras.nix` uses `programs.swaylock` with `package = null` so HM writes `~/.config/swaylock/config` (appearance only — catppuccin mocha colors, font, indicator) while pacman provides the binary + PAM.
- **polkit-gnome** — auth agent; the polkit daemon is system-level. Spawned by niri's `spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"` (full path because `/usr/lib/polkit-gnome` isn't on `$PATH`).
- **blueman + blueman-applet** — system bluetooth service + tray applet. `blueman-applet` spawned by niri.
- **nm-applet** — NetworkManager tray applet. NetworkManager is pacstrap-installed (§2); `nm-applet` added to §5; spawned by niri.
- **xdg-desktop-portal + xdg-desktop-portal-gtk + xdg-desktop-portal-gnome** — dbus-activated, configured by `niri-portals.conf` shipped by the niri package. No HM `xdg.portal` config — niri's shipped config is sufficient.
- **pipewire + wireplumber + pipewire-pulse + pipewire-alsa** — systemd user services (units at `/usr/lib/systemd/user/`). Enable once after first boot: `systemctl --user enable --now pipewire pipewire-pulse wireplumber` (see `INSTALL.md` §6). `pipewire-jack` deliberately NOT installed (plan spec).
- **Fonts** (`ttf-jetbrains-mono-nerd`, `ttf-cascadia-code-nerd`, `noto-fonts-emoji`, `ttf-inter`) — pacman base (plan spec "base fonts"). HM modules reference the family names (wezterm/fuzzel/mako/waybar); the font packages themselves stay at pacman.
- **BT audio codecs** (`libldac`, `libfreeaptx`) — pacman libraries for LDAC/aptX on ANC headphones. `libldacbt-abx` is AUR-only — see `INSTALL.md` §5 note.
- **Intel media accel** (`intel-media-driver`, `vulkan-intel`, `libva-mesa-driver`, `libva-intel-driver`, `vulkan-mesa-layers`, `mesa`) — pacman libraries for Meteor Lake video encode/decode. No HM config.

### Wallpaper

`spawn-at-startup "swaybg" "-c" "#1e1e2e" "-m" "fill"` in `home/niri.nix` sets a solid catppuccin mocha base color as the default wallpaper. To use an image, edit that line to `spawn-at-startup "swaybg" "-i" "/path/to/wallpaper.jpg" "-m" "fill"` and `home-manager switch`.

### Screenshots

`Super+Shift+S` runs `grim -g "$(slurp)" - | wl-copy` (region selection via slurp → capture via grim → pipe to Wayland clipboard via wl-copy). Clipboard-only, no file save. swappy deliberately NOT installed (plan spec). Alternative: niri's built-in `screenshot` action (saves to file too — would need `screenshot-path` set, see #7 handoff).

### Lock + idle

- **swaylock** (`Super+Esc`): catppuccin mocha appearance via `programs.swaylock` (see above). `swaylock -f` (daemonized, `-f` flag) is what swayidle runs on idle/sleep.
- **swayidle** (spawned at niri startup): 300s idle → `swaylock -f` (lock); 301s → `niri msg action power-off-monitors` (1s after lock so the lock screen is drawn first, saves power); `before-sleep` → `swaylock -f` (covers lid-close → logind suspend). Adjust the 300/301 timeouts in `home/niri.nix` if you want a different idle delay. The `before-sleep` lid-close coverage relies on logind's default `HandleLidSwitch=suspend` — if you set `HandleLidSwitch=ignore` or `=lock` in `/etc/systemd/logind.conf`, lid-close won't trigger suspend and `before-sleep` won't fire; in that case add a `lock` event hook to swayidle or set `HandleLidSwitch=lock` (logind locks directly).

### Spawn-at-startup vs systemd user services

All #8 components use niri's `spawn-at-startup` (not HM's `systemd.user.services` / `services.swayidle` / `services.blueman-applet` / `services.network-manager-applet`). This matches the #7 pattern for waybar/mako: simpler, works without niri's systemd integration, and avoids the `config.wayland.systemd.target` dependency that HM's swayidle/blueman-applet modules would need. Trade-off: no `systemctl --user status swaybg` (it's a child of niri, not a systemd unit). The niri wiki documents both approaches — see `Example systemd Setup` if you prefer the systemd path.

## Packages

User-space CLI tools, language runtimes, and btop are managed by `home/packages.nix` (ticket #9). All installed via Home Manager — none of these are in the `INSTALL.md` §5 pacman list.

### CLI tools (HM-installed)

`eza`, `bat`, `ripgrep`, `fd`, `jq`, `yq-go` (Mike Farah's Go yq — matches what Scoop ships on Windows; the binary is still `yq`), `yazi`, `lazygit`, `gh`. `gh` has no ported config — run `gh auth login --web` once after first boot (the auth token lives in `~/.config/gh/hosts.yml`, outside HM's scope).

`fzf`, `zoxide`, and `starship` are installed by `home/zsh.nix` (#3) via their HM modules (`programs.fzf` / `programs.zoxide` / `programs.starship`) with zsh integrations and config — not duplicated in `home/packages.nix`.

### Languages (HM-installed)

`python3` + `uv` (Python package manager), `nodejs`, `rustup`, `terraform`, `android-tools` (adb + fastboot, replaces the Windows Scoop `adb`). **Rust post-switch step**: `rustup` ships no default toolchain — after `home-manager switch`, run `rustup default stable` to install the stable toolchain (`rustc`, `cargo`, etc.). The HM module installs the `rustup` binary only; it does not pin a toolchain (matches the plan spec footgun: on Linux the `rustup` package path situation is simpler than Windows — just `rustup default stable` post-install).

### btop (HM-installed + ported config)

`programs.btop.enable` installs `btop`; `programs.btop.settings` ports the config from the Windows `scoop/persist/btop/btop.conf`. Port changes Windows → Linux:

- `color_theme` changed from the Windows absolute path (`C:\Users\student\scoop\apps\btop\current\themes\tokyo-night.theme`) to the bare theme name `"tokyo-night"` — btop Linux resolves it via `~/.config/btop/themes/` then the package's shipped themes (nixpkgs btop ships the same upstream themes as btop4win, including tokyo-night).
- **Dropped btop4win-only options**: `enable_ohmr` (Libre Hardware Monitor DLL — Windows-only), `show_gpu` / `selected_gpu` / `gpu_mem_override` (LHM GPU monitoring — no btop Linux equivalent for Intel Arc integrated), `rounded_corners` (btop4win terminal rendering — btop Linux uses character-based corners), `cpu_graph_lower = "gpu"` (btop4win GPU graph).
- **Omitted empty-value options** (`cpu_sensor`, `custom_cpu_name`, `disks_filter`, `io_graph_speeds`, `net_iface`) so btop's auto-detect defaults apply on Linux.
- Everything else ported verbatim: `vim_keys = true`, `update_ms = 1500`, `proc_sorting = "cpu direct"`, `graph_symbol = "braille"`, `shown_boxes = "cpu mem net proc"`, `temp_scale = "celsius"`, `clock_format = "%X"`, `show_battery = true`, `log_level = "WARNING"`, etc.

### AUR-only (NOT in nix)

`zen-browser` and `anki-bin` are AUR-only — not in nixpkgs, not in `home/packages.nix`. Install after the §10 yay bootstrap:

```bash
yay -S zen-browser-bin anki-bin
```

See `INSTALL.md` §5 "AUR bootstrap" for the one-time `yay-bin` install.

## ntfy

The ntfy subscription client is managed by `home/ntfy.nix` (ticket #10). It replaces the Windows VBS hidden launcher + snoretoast with a persistent systemd user service that subscribes to the `shift-automator-doomax` topic on ntfy.sh and fires `notify-send` (libnotify) toasts on incoming messages — which mako renders as desktop notifications.

HM release-25.11 has no `programs.ntfy` / `services.ntfy-sh` module, so the module installs the packages, writes `~/.config/ntfy/client.yml` via `xdg.configFile`, and defines the `ntfy-client` systemd user service by hand (same fallback pattern as `home/niri.nix` writing `config.kdl`).

### Packages (HM-installed)

`ntfy-sh` (provides the `ntfy` CLI — publish + subscribe in one binary) and `libnotify` (provides `notify-send`, replacing Windows snoretoast). Neither is in the `INSTALL.md` §5 pacman list.

### client.yml

Ported from the Windows `AppData/Roaming/ntfy/client.yml`. Port changes Windows → Linux:

- `command` switched from `snoretoast -t "%NTFY_TITLE%" -m "%NTFY_MESSAGE%"` to `notify-send "$title" "$message"`. `$title` / `$message` are ntfy's short env-var aliases for `$NTFY_TITLE` / `$NTFY_MESSAGE` (see `ntfy subscribe` docs); double-quoted so spaces in the title/body survive the shell.
- The `exit /b 0` line is **dropped**. It existed only because snoretoast exits non-zero on success, which ntfy logged as "Command failed". `notify-send` exits 0 on success, so the normalization is unnecessary.

To add a topic: edit the `subscribe:` list in `home/ntfy.nix`, `home-manager switch --flake .#bobbytables`, then `systemctl --user restart ntfy-client`.

### systemd user service

`systemd.user.services.ntfy-client` runs `ntfy subscribe --from-config` persistently. `wantedBy = ["default.target"]` auto-starts it at user session login; `Restart = on-failure` retries if the daemon exits (matching the unit shipped by the upstream deb package — see the ntfy-tablet-setup-2026-07-11 handoff). After `home-manager switch`, the service is enabled and started automatically — no manual `systemctl --user enable` needed.

### Verify

```bash
systemctl --user status ntfy-client --no-pager
ntfy pub --title="test" shift-automator-doomax "hi"          # expect a mako toast, no "Command failed" in the journal
journalctl --user -u ntfy-client --no-pager -n 10
```

## opencode

The opencode CLI config is managed by `home/opencode.nix` (ticket #11). The opencode binary itself is NOT installed by Home Manager — it is a Node CLI installed out-of-band (`npm i -g opencode` or the user's bootstrap). HM only writes the config files under `~/.config/opencode/` that opencode reads at startup.

HM release-25.11 has no `programs.opencode` module, so the module writes each config file via `xdg.configFile."opencode/<path>".text = ''...''` (flush-left per the wezterm/nvim/ntfy convention).

### HM-managed

- `opencode/opencode.json` — provider block (NVIDIA NIM, `{env:NVIDIA_API_KEY}` templating), model picks (`nvidia/z-ai/glm-5.2` main, `nvidia/minimaxai/minimax-m3` small + build agent). Ported verbatim; no Windows paths to replace (the file is path-free).
- `opencode/opencode.jsonc` — schema-ref-only override file. Ported verbatim (trailing newline added for POSIX compliance — the Windows source had none).
- `opencode/commands/` — 6 slash commands: `commit` (scoped commits + push), `learn` (extract session learnings to AGENTS.md), `rmslop` (strip AI code slop), `plannotator-annotate` / `plannotator-last` / `plannotator-review` (Plannotator UI triggers).
- `opencode/modes/docs.md` — documentation-writing mode (relaxed tone, 2-sentence chunks, `docs:` commit prefix).

The Windows source had both `command/` (singular) and `commands/` (plural) directories. opencode reads `commands/` (plural) — that is the canonical dir. The 3 files unique to `command/` (`commit.md`, `learn.md`, `rmslop.md`) are merged into `commands/` here. The `plannotator-*` files were identical in both dirs (verified by diff), so no content is lost.

### Not HM-managed (left user-managed)

- `~/.config/opencode/AGENTS.md` — OS-specific, hand-edited (the Windows AGENTS.md has ADB/Termux/Tasker/Windows-path notes that don't apply on Linux). Recreate on the target with Linux-specific content, or symlink to a maintained copy in `~/notes/`.
- `~/.config/opencode/skills/` — skills are user-installed via `npx skills add -g` to `~/.agents/skills/` (user-level, per the ticket). The config-level `skills/` dir is left empty; HM does not create it. Reinstall skills on the target with `npx skills add -g mattpocock/skills` (or whichever sources).
- `~/.config/opencode/package.json`, `node_modules/`, `package-lock.json` — opencode regenerates these when plugins or MCP servers are installed. Not HM's concern.
- `~/.config/opencode/.gitignore` — HM is the source of truth for the managed files; no per-dir git tracking needed.

### Port changes Windows → Linux

The port is **content-identical modulo newline normalization** — the Windows sources used CRLF, the Nix `''...''` strings render as LF (correct for Linux). No path rewrites were needed (opencode.json is path-free; the command/mode files are markdown with no OS-specific paths).

### Environment

`OPENCODE_DISABLE_AUTOUPDATE=true` is set in `home/zsh.nix` (#3, line 72) — prevents opencode from self-updating under the HM-managed config (HM is the source of truth). `PLANNOTATOR_DATA_DIR="$HOME/notes/docs/plannotator"` is also set there. `NVIDIA_API_KEY` is sourced from `~/notes/*.env` (the `for f in ~/notes/*.env(N)` loop in zsh.nix) — secrets stay out of HM.

### Verify

```bash
# Config files are HM-managed symlinks to the nix store
ls -la ~/.config/opencode/opencode.json ~/.config/opencode/commands/commit.md ~/.config/opencode/modes/docs.md

# opencode launches and reads the ported config
opencode --version
opencode run --command commit          # /commit slash command works (uses commands/commit.md)

# Provider env var is set (sourced from ~/notes/*.env by zsh.nix)
test -n "$NVIDIA_API_KEY" && echo set || echo unset

# Skills discoverable at ~/.agents/skills/ (user-level, not HM-managed)
ls ~/.agents/skills/ | head             # empty until `npx skills add -g` is run on the target
```

## Spec

Authoritative plan (45 decisions + footguns): [`notes/handoff/arch-nix-niri-plan-2026-07-21.md`](https://github.com/jitumaatgit/dotfiles/blob/main/notes/handoff/arch-nix-niri-plan-2026-07-21.md) — lives in the private `notes` repo; see the handoff doc at `notes/handoff/arch-nix-niri-tickets-2026-07-21.md` for the ticket frontier.
