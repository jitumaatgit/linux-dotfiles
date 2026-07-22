# Arch ISO USB on Windows 11 (pre-flight for INSTALL.md §0)

`INSTALL.md` §0 says "boot the latest Arch ISO over UEFI" but doesn't cover how to make the USB on the Windows host. Non-obvious findings from doing this on Windows 11 + Git Bash:

- **`dd` from Git Bash cannot write to Windows raw devices.** `dd.exe` (MSYS) fails with "Is a directory" on `\\.\PhysicalDrive1` even with `MSYS_NO_PATHCONV=1` — it treats Windows raw device paths as UNC paths and tries to mount them. Don't use it for USB imaging.
- **PowerShell `FileStream` raw write to USB is unreliable.** `New-Object IO.FileStream "\\.\PhysicalDrive1", "Open", "Write"` fails with "Incorrect function" or "The device is not ready" on many USB sticks. Not a viable method.
- **`Mount-DiskImage` may not return a drive letter.** On some Windows 11 systems the ISO mounts but `Get-Volume | Where DriveType -eq 'CD-ROM'` returns empty — no auto-assigned letter. Don't rely on this for robocopy.
- **Working CLI method: 7zip extraction to a FAT32-formatted USB.** This is the reliable approach with scoop-installed `7zip`:
  1. `diskpart` (admin) → `select disk 1` / `clean` / `create partition primary` / `format fs=fat32 quick label=ARCHISO` / `assign` → USB gets a drive letter (e.g. `E:`).
  2. `7z x C:\path\to\archlinux.iso -oE:\ -y -aoa` — extracts the ISO contents to the USB root.
  3. Verify `E:\EFI\BOOT\BOOTX64.EFI` exists (~1.5 MB) — that's the UEFI removable-media bootloader. Arch ISO is designed for this; `dd` imaging is not required for UEFI boot.
- **All raw-disk operations need admin.** Run via `Start-Process -Verb RunAs`. Non-admin `dd` gets "Permission denied".
- **Card reader vs real USB stick in `diskpart`:** "No Media" / `0 B` status means the enumerated device is a card reader with no card seated (or a dead stick) — not a software problem. A real USB stick shows actual size and `Removable Media` type.
- **Latest ISO URL pattern:** `https://geo.mirror.pkgbuild.com/iso/<YYYY.MM.DD>/archlinux-<YYYY.MM.DD>-x86_64.iso`. Check `https://archlinux.org/releng/releases/` for the latest date. ISO is ~1.5 GB.
- **`/tmp` in Git Bash is not `C:\tmp`.** It maps to the MSYS install (`C:\msys64\tmp` or similar) which admin PowerShell can't see. Copy files to `$env:LocalAppData\Temp` (i.e. `C:\Users\<user>\AppData\Local\Temp`) before passing paths to admin-elevated scripts.
