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

## Spec

Authoritative plan (45 decisions + footguns): [`notes/handoff/arch-nix-niri-plan-2026-07-21.md`](https://github.com/jitumaatgit/dotfiles/blob/main/notes/handoff/arch-nix-niri-plan-2026-07-21.md) — lives in the private `notes` repo; see the handoff doc at `notes/handoff/arch-nix-niri-tickets-2026-07-21.md` for the ticket frontier.
