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

## Spec

Authoritative plan (45 decisions + footguns): [`notes/handoff/arch-nix-niri-plan-2026-07-21.md`](https://github.com/jitumaatgit/dotfiles/blob/main/notes/handoff/arch-nix-niri-plan-2026-07-21.md) — lives in the private `notes` repo; see the handoff doc at `notes/handoff/arch-nix-niri-tickets-2026-07-21.md` for the ticket frontier.
