#!/usr/bin/env bash
# Apply /etc/keyd/default.conf from this repo and restart keyd.
# Lives in docs/keyd/ — colocated with the config it installs.
#
# Usage:  sudo ~/linux-dotfiles/docs/keyd/apply.sh
set -euo pipefail

REPO_SRC="$(dirname "$(readlink -f "$0")")/default.conf"
DEST=/etc/keyd/default.conf

[[ -r "$REPO_SRC" ]] || { echo "missing $REPO_SRC" >&2; exit 1; }

install -m 0644 -o root -g root "$REPO_SRC" "$DEST"
keyd check "$DEST" >/dev/null   # abort via set -e if config is malformed
systemctl restart keyd
sleep 0.2

echo "=== keyd status ==="
systemctl is-active keyd
echo
echo "=== verify grab: fuser should now show BOTH 'niri' AND 'keyd' on event3 ==="
fuser -v /dev/input/event3 2>&1 || true
echo
echo "=== verify CapsLock: press it now — the LED should NOT light ==="
echo "(look at the CapsLock LED above; if it lights, keyd still isn't grabbing.)"
echo
echo "=== next: capture the Copilot scancode ==="
echo "run:  sudo keyd monitor"
echo "press the Copilot key once, then Ctrl-C, and paste the output back."
