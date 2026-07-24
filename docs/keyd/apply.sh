#!/usr/bin/env bash
# Apply /etc/keyd/*.conf from this repo and restart keyd.
# Lives in docs/keyd/ — colocated with the configs it installs.
#
# Usage:  sudo ~/linux-dotfiles/docs/keyd/apply.sh
set -euo pipefail

REPO_DIR="$(dirname "$(readlink -f "$0")")"
DEST_DIR=/etc/keyd

shopt -s nullglob
confs=("$REPO_DIR"/*.conf)
((${#confs[@]})) || { echo "missing *.conf in $REPO_DIR" >&2; exit 1; }

# Remove stale configs in /etc/keyd that no longer exist in the repo,
# so this directory stays the single source of truth.
for dest in "$DEST_DIR"/*.conf; do
  base="$(basename "$dest")"
  [[ -f "$REPO_DIR/$base" ]] || rm -f "$dest"
done

for src in "${confs[@]}"; do
  install -m 0644 -o root -g root "$src" "$DEST_DIR/$(basename "$src")"
done

# systemd drop-in: restart keyd on failure (stock unit has Restart=no).
# Lives in systemd/ so the *.conf glob above (keyd configs) never picks it up —
# a drop-in inside /etc/keyd makes `keyd check` fail and aborts this script.
install -Dm 0644 -o root -g root "$REPO_DIR/systemd/restart.conf" \
  /etc/systemd/system/keyd.service.d/restart.conf

keyd check >/dev/null   # validates ALL files in /etc/keyd; abort via set -e if malformed
systemctl daemon-reload
systemctl restart keyd
sleep 0.2

echo "=== keyd status ==="
systemctl is-active keyd
echo
echo "=== installed configs ==="
ls -l "$DEST_DIR"
echo
echo "=== manual checks ==="
echo "laptop kbd : CapsLock hold=Ctrl tap=Esc; left Alt<->Super swapped; right Alt=Ctrl; Copilot=Alt"
echo "Magi65     : Caps key hold=Ctrl tap=Esc; modifiers stock (no swap)"
echo "debug ids  : sudo keyd monitor"
