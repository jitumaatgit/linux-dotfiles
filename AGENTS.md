## Arch ISO USB on Windows 11 (pre-flight for INSTALL.md §0)

`INSTALL.md` §0 says "boot the latest Arch ISO over UEFI" but doesn't cover how to make the USB on the Windows host. See [`docs/arch-iso-usb-windows.md`](docs/arch-iso-usb-windows.md) for the working method (diskpart FAT32 + 7zip extraction) and the failed approaches (Git Bash `dd`, PowerShell `FileStream`, `Mount-DiskImage`).

## Agent skills

### Issue tracker

GitHub Issues on `jitumaatgit/linux-dotfiles`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles using default names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo. `CONTEXT.md` at root. See `docs/agents/domain.md`.