# Arch + Nix + Niri — Install Walkthrough

Walks a human from a blank NVMe to a booted Arch system with Nix + Home Manager ready for `home-manager switch --flake .#bobbytables` against this repo.

Hardware target: **Dell Latitude 7450** — 32GB RAM, 512GB Samsung PM9C1a NVMe, Intel Core Ultra 7 165U (Meteor Lake), Intel Arc Graphics (integrated, no NVIDIA), Intel Wi-Fi 7 BE200 (no ethernet), Intel Wireless Bluetooth.

System-level config that Home Manager cannot manage (`/etc/keyd/default.conf`, `/etc/pacman.d/hooks/snap.hook`, zram-generator, fstab, greetd, services) lives in this document. Everything user-space is declarative via the flake.

---

## 0. Pre-flight (Arch ISO)

Boot the latest Arch ISO over UEFI. Then:

```bash
# Confirm UEFI mode (must show 64-bit EFI)
ls /sys/firmware/efi/efivars

# Connect Wi-Fi (no ethernet on this machine)
iwctl
# [iwctl] station wlan0 scan
# [iwctl] station wlan0 connect "<SSID>"
# [iwctl] quit

# Update the system clock
timedatectl set-ntp true

# Identify the NVMe (expect /dev/nvme0n1)
lsblk
```

---

## 1. Partitioning — GPT/EFI + btrfs

Single NVMe, GPT, one EFI partition + one btrfs partition. No encryption (decision: laptop-theft tradeoff accepted).

```bash
# Wipe and partition
sgdisk -Z /dev/nvme0n1
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI" /dev/nvme0n1
sgdisk -n 2:0:0   -t 2:8300 -c 2:"root" /dev/nvme0n1
sgdisk -p /dev/nvme0n1

# Format
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L arch -f /dev/nvme0n1p2
```

### btrfs subvolumes

Create subvolumes before mounting. `@snapshots` holds the pacman-hook snapshots (see §7) — kept on its own subvolume so snapshots of `@` do not nest previous snapshots.

```bash
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

### Mount with zstd + async discard

`compress=zstd` (default level 3) and `discard=async` (NVMe async TRIM — NOT `fstrim.timer`). `space_cache=v2` is the modern btrfs default.

```bash
mount -o rw,relatime,compress=zstd,space_cache=v2,subvol=/@,discard=async /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{home,.snapshots,boot/efi}
mount -o rw,relatime,compress=zstd,space_cache=v2,subvol=/@home,discard=async /dev/nvme0n1p2 /mnt/home
mount -o rw,relatime,compress=zstd,space_cache=v2,subvol=/@snapshots,discard=async /dev/nvme0n1p2 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot/efi
```

### fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

The resulting `/etc/fstab` must use these btrfs options (verify after genfstab and edit if needed):

```
# / (btrfs, subvol=@)
UUID=<root-uuid>  /            btrfs   rw,relatime,compress=zstd,space_cache=v2,subvol=/@,discard=async  0 0
# /home (btrfs, subvol=@home)
UUID=<root-uuid>  /home        btrfs   rw,relatime,compress=zstd,space_cache=v2,subvol=/@home,discard=async  0 0
# /.snapshots (btrfs, subvol=@snapshots)
UUID=<root-uuid>  /.snapshots  btrfs   rw,relatime,compress=zstd,space_cache=v2,subvol=/@snapshots,discard=async  0 0
# /boot/efi (FAT32)
UUID=<efi-uuid>   /boot/efi    vfat    rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro  0 2
```

> **Footgun**: `discard=async` is the NVMe TRIM mechanism. Do NOT enable `fstrim.timer` — async discard on mount is the chosen path. See plan spec footgun "`discard=async` not `fstrim.timer`".

---

## 2. pacstrap + chroot

Minimal base only — the rest of the user-facing packages go in §5 (post-boot) or into Home Manager.

```bash
pacstrap -K /mnt base base-devel linux linux-lts linux-firmware intel-ucode \
  btrfs-progs vim networkmanager sudo zsh

arch-chroot /mnt
```

---

## 3. System basics — locale, timezone, hostname, user, sudo

```bash
# Timezone + hwclock
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

# Locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "archbook" > /etc/hostname

# Root password
passwd
```

### Create user `bobbytables` with zsh login shell

```bash
useradd -m -G wheel,libvirt -s /usr/bin/zsh bobbytables
passwd bobbytables
```

> **Login shell vs HM**: the **login shell** is set here at user creation (`-s /usr/bin/zsh`) — Home Manager does NOT manage the login shell (that requires `chsh`/`usermod`, which is system-level). HM manages the zsh **config** (`.zshrc`, plugins, env, starship) via the `home/zsh.nix` module (ticket #3).

### Sudo — interactive password, NO NOPASSWD

```bash
visudo
# Uncomment:  %wheel ALL=(ALL:ALL) ALL
# Do NOT add: %wheel ALL=(ALL:ALL) NOPASSWD: ALL
```

Decision: interactive password (agent + VMs = don't auto-root). See plan spec.

---

## 4. systemd-boot — entries for `linux` + `linux-lts`

```bash
bootctl install
```

### `/boot/loader/loader.conf`

```
default arch
timeout 4
console-mode max
editor no
```

### `/boot/loader/entries/arch.conf`

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=<root-uuid> rootflags=subvol=/@ rw
```

### `/boot/loader/entries/arch-lts.conf`

```
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /initramfs-linux-lts.img
options root=UUID=<root-uuid> rootflags=subvol=/@ rw
```

Replace `<root-uuid>` with the UUID of `/dev/nvme0n1p2` (`blkid /dev/nvme0n1p2`). `intel-ucode.img` is loaded first for microcode updates.

Kernel: `linux` mainline (Meteor Lake wants recent kernels) + `linux-lts` fallback (recovery). See plan spec "Kernel" decision.

---

## 5. Base pacman packages — irreducible base only

The system-level set (kernel, systemd, mesa, libvirt, greetd, niri, fonts, network, power, firmware, firewall, printing, input, audio, bluetooth, Wayland support stack). **All user-space dotfiles + CLI tools + languages come from Home Manager** — do not pacman-install them here.

```bash
pacman -S --needed \
  linux-headers linux-lts-headers \
  systemd-sysvcompat dosfstools mtools \
  \
  mesa vulkan-intel vulkan-mesa-layers intel-media-driver libva-mesa-driver libva-intel-driver \
  \
  thermald power-profiles-daemon fwupd ufw \
  cups cups-pdf \
  \
  libvirt virt-manager qemu-desktop edk2-ovmf dnsmasq \
  \
  keyd \
  \
  pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol \
  \
  bluez blueman libldac libfreeaptx \
  \
  brightnessctl grim slurp swaybg swaylock swayidle \
  polkit-gnome xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
  \
  greetd greetd-tuigreet \
  \
  niri xorg-xwayland \
  \
  ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd noto-fonts-emoji ttf-inter \
  \
  zram-generator
```

> **waybar / mako / fuzzel are NOT in this list** — they are installed by Home Manager (nixpkgs) via `home/waybar.nix`, `home/mako.nix`, `home/fuzzel.nix` (ticket #7). Only `niri` + `xorg-xwayland` stay at the pacman level because greetd launches `niri-session` before any HM generation is active. Adding them here too would double-install (HM's `~/.nix-profile/bin` copy would shadow `/usr/bin`).

> **Bluetooth codecs**: the plan spec lists `libldac + libfreeaptx + libldacbt-abx` for LDAC/aptX on the ANC headphones. `libldac` and `libfreeaptx` are in the official repos (above). If `libldacbt-abx` is not found, install it via AUR after §10 (yay) — `yay -S libldacbt-abx` (verify the package exists at install time; LDAC/aptX still works with just `libldac` + `libfreeaptx` on modern pipewire).

> **Dropped vs a generic Arch desktop**: no `ntfs-3g` (no Windows dual boot), no `nvidia` (integrated Intel only), no `networkmanager-openvpn` (use HM/user-space if needed later), no `gdm`/`sddm` (greetd replaces), no `snapper`/`timeshift` (manual snapshots + pacman hook, see §7).

### AUR bootstrap — `yay-bin`

`yay` is AUR-only (for zen-browser, anki-bin, and any codec packages not in official repos). Install after first boot as `bobbytables`:

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
cd /tmp/yay-bin && makepkg -si
```

---

## 6. Services to enable

```bash
# Network + DNS + time + OOM + power + firmware
systemctl enable NetworkManager systemd-resolved systemd-timesyncd systemd-oomd \
  thermald power-profiles-daemon fwupd

# Firewall + printing + VMs + bluetooth
systemctl enable ufw cups libvirtd bluetooth

# Display manager → niri-session (see §8 for greetd config)
systemctl enable greetd

# Input remapping (see §7 for keyd config)
systemctl enable keyd
```

### systemd-resolved integration

```bash
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### ufw — default deny incoming

```bash
ufw default deny incoming
ufw default allow outgoing
ufw enable
```

> **Footgun**: do NOT enable `fstrim.timer`. NVMe TRIM is handled by the `discard=async` btrfs mount option (§1). Enabling both is redundant; async discard is the chosen path.

> **Footgun**: `thermald` is a root service; `power-profiles-daemon` (PPD) is the user-facing toggle (`powerprofilesctl`). Do not try to make thermald user-controllable. See plan spec.

### Optional first-run firmware check (after first boot)

```bash
fwupdmgr get-devices
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
```

This is the only firmware path once Windows is wiped (Dell LVFS).

---

## 7. System-level config files (not HM-managed)

### `/etc/keyd/default.conf` — Caps tap=Esc, hold=Ctrl

```
[Global]
default = main

[main]
capslock = overload(control, esc)
```

`overload(control, esc)` = hold for Control, tap for Esc. Applies globally to both keyboards (built-in + MG65 BT3).

> **Footgun**: do NOT remap RWin→LCtrl. That was a Windows AHK thing. On Linux, Super is Niri's Mod key — keep RWin as Super. See plan spec.

`keyd` service enabled in §6.

### `/etc/pacman.d/hooks/snap.hook` — auto-snapshot before every pacman transaction

```
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Taking btrfs snapshot of @ before pacman transaction
When = PreTransaction
Exec = /usr/local/bin/snap-pacman
Depends = btrfs-progs
AbortOnFail
```

### `/usr/local/bin/snap-pacman` — the snapshot script

```bash
#!/bin/sh
set -eu
ts=$(date +%Y%m%d-%H%M%S)
btrfs subvolume snapshot -r / /.snapshots/pre-update-"$ts"
```

```bash
chmod +x /usr/local/bin/snap-pacman
```

The snapshot targets `@` (mounted at `/`) and lands on `@snapshots` (mounted at `/.snapshots`) — a separate subvolume, so snapshots of `@` do not nest previous snapshots. Rolling back: boot `linux-lts`, `btrfs subvolume set-default @snapshots/pre-update-<ts>` (or `btrfs subvolume snapshot` over `@`), reboot.

A manual `snap` shell function for pre-flight snapshots on demand lives in `.zshrc` (added by ticket #3's `home/zsh.nix`).

### `/etc/systemd/zram-generator.conf` — zram swap, no disk swap, no hibernation

```
# /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
```

32GB RAM → 16GB zstd-compressed zram swap. No disk swap partition, no hibernation (laptop, RAM sufficient). `zram-generator` creates `systemd-zram-setup@zram0.service` automatically at boot when this config is present — no explicit `systemctl enable` needed.

---

## 8. greetd → niri-session

### `/etc/greetd/config.toml`

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd niri-session"
user = "greeter"
```

`tuigreet` prompts for login; on auth, launches `niri-session` (provided by the `niri` package). `--remember` keeps the last username; `--time` shows the clock.

greetd service enabled in §6.

---

## 9. Nix package manager + Home Manager (standalone)

### Nix — Determinate Systems installer

Flakes enabled by default, idempotent, cleaner uninstall than the official installer:

```bash
sh <(curl -L https://install.determinate.systems/nix) --daemon
```

Re-open the shell or `source /etc/profile.d/nix.sh` to get `nix` on PATH.

### Home Manager — standalone install

Install HM as a standalone tool (the release branch goes in the flake URL path, not as an attribute):

```bash
nix profile install github:nix-community/home-manager/release-25.11#home-manager
```

This puts `home-manager` on PATH permanently. The flake in this repo also pulls HM as an input (for `homeConfigurations.bobbytables`), but the standalone install lets you run `home-manager switch` directly without `nix run` each time.

> **Alternative first run** (no permanent HM install): `nix run github:nix-community/home-manager/release-25.11 -- switch --flake .#bobbytables`. After the first switch, `home-manager` is on PATH from the home generation and subsequent runs use `home-manager switch` directly.

> **Footgun**: this is standalone Home Manager, NOT a NixOS module. There is no `nixos-rebuild`, no `/etc/nixos/configuration.nix`, no `nixosConfigurations`. The system is Arch (pacman-managed); only user-space is declarative via HM. See plan spec.

---

## 10. Exit chroot + first boot

```bash
exit              # leave chroot
umount -R /mnt    # verify clean unmount
reboot            # remove ISO, boot into Arch
```

On first boot, log in as `bobbytables` at the greetd tuigreet prompt → launches `niri-session`.

---

## 11. What to clone next

After first boot, with Nix + HM installed (§9):

```bash
git clone https://github.com/jitumaatgit/linux-dotfiles.git ~/linux-dotfiles
cd ~/linux-dotfiles
home-manager switch --flake .#bobbytables
```

This applies the skeleton (ticket #1). Subsequent tickets (#3 zsh, #4 git, #5 wezterm, #6 nvim, #7 niri, #8 niri-extras, #9 packages, #10 ntfy, #11 opencode) plug modules into `home.nix` — re-run `home-manager switch --flake .#bobbytables` after each lands.

### SSH key for git signing

```bash
ssh-keygen -t ed25519 -C "jitumaat@protonmail.com" -f ~/.ssh/id_ed25519
gh auth login --web   # add the public key to GitHub
```

Git signing is SSH (not GPG): ticket #4's `home/git.nix` sets `gpg.format = ssh`, `user.signingkey = ~/.ssh/id_ed25519`, `commit.gpgsign = true`.

---

## Checklist (acceptance criteria for ticket #2)

- [x] GPT/EFI partitioning, btrfs subvolumes `@` + `@home` (+ `@snapshots` for the pacman hook) with zstd compression
- [x] systemd-boot with entries for `linux` and `linux-lts`
- [x] fstab btrfs mount options documented with `discard=async` + zstd (NOT `fstrim.timer`)
- [x] Nix (Determinate Systems installer) + Home Manager standalone install
- [x] Base pacman package list documented (kernel, systemd, mesa, libvirt, greetd, niri, base fonts, NetworkManager, thermald, fwupd, ufw, cups, keyd, audio, bluetooth, Wayland stack)
- [x] Services to enable documented (NetworkManager, systemd-resolved, systemd-timesyncd, systemd-oomd, thermald, power-profiles-daemon, greetd→niri-session, ufw, cups, libvirtd, bluetooth; fstrim NOT enabled)
- [x] `/etc/keyd/default.conf`: Caps tap=Esc, hold=Ctrl; NO RWin→LCtrl remap
- [x] `/etc/pacman.d/hooks/snap.hook` + `snap-pacman` script: auto-snapshot before every `pacman -Syu`
- [x] zram-generator config (no disk swap, no hibernation)
- [x] User `bobbytables` created with zsh login shell (HM manages zsh config, not the login shell)
- [x] Hostname `archbook`, TZ `America/Los_Angeles`, locale `en_US.UTF-8`
- [x] Sudo configured with interactive password (no NOPASSWD)
- [x] Closing "what to clone next" section: `linux-dotfiles` → `home-manager switch --flake .#bobbytables`
