{ pkgs, ... }:

{
  # ntfy subscription client — replaces the Windows VBS hidden launcher.
  # Source: Windows AppData/Roaming/ntfy/client.yml (snoretoast + `exit /b 0`),
  # ported to notify-send (libnotify) + a persistent systemd user service.
  #
  # No exit-code normalization: the Windows `exit /b 0` existed because
  # snoretoast exits non-zero on success, which ntfy logged as "Command
  # failed". notify-send exits 0 on success, so the workaround is dropped
  # (see ticket #10 acceptance criteria).
  #
  # HM release-25.11 has no `programs.ntfy` / `services.ntfy-sh` module, so
  # this module installs the package, writes ~/.config/ntfy/client.yml via
  # xdg.configFile, and defines the ntfy-client systemd user service by
  # hand — same fallback pattern as home/niri.nix writing config.kdl.
  home.packages = with pkgs; [
    ntfy-sh      # ntfy CLI (publish + subscribe; same binary as the self-host server)
    libnotify    # notify-send (replaces Windows snoretoast)
  ];

  # Ported from AppData/Roaming/ntfy/client.yml.
  # `$title` / `$message` are ntfy's short env-var aliases for $NTFY_TITLE /
  # $NTFY_MESSAGE (see `ntfy subscribe` docs). Double-quoted so spaces in the
  # title/body survive the shell. YAML single-quoted so the double quotes
  # inside stay literal without backslash escaping.
  #
  # The command invokes a wrapper (desktop-notify.sh) instead of bare
  # notify-send: under the systemd unit PATH, bare notify-send may not resolve
  # (exit 127), and the wrapper sets `-a ntfy` so omp-ntfy-forward's app_name
  # whitelist never re-publishes our own popups (loop guard).
  xdg.configFile."ntfy/client.yml".text = ''
default-host: https://ntfy.sh

subscribe:
  - topic: shift-automator-doomax
    command: '/home/bobbytables/.config/ntfy/desktop-notify.sh "$title" "$message"'
'';

  # Wrapper invoked by `ntfy subscribe --from-config` for each received message.
  # Sets app_name to `ntfy` (via `notify-send -a ntfy` or busctl fallback) so the
  # omp-ntfy-forward.service bus monitor (app_name whitelist) never re-publishes
  # these popups.
  xdg.configFile."ntfy/desktop-notify.sh" = {
    text = ''
#!/usr/bin/env bash
# $1 = title (may be empty), $2 = message
# app_name is always `ntfy` — Part 2's forwarder whitelists omp's app_name,
# guaranteeing ntfy popups are never re-forwarded.
set -euo pipefail

title="''${1:-ntfy}"
body="$2"

if command -v notify-send >/dev/null 2>&1; then
  notify-send -a ntfy "$title" "$body"
else
  busctl call --user org.freedesktop.Notifications /org/freedesktop/Notifications \
    org.freedesktop.Notifications.Notify susssasa{sv}i \
    ntfy 0 "" "$title" "$body" 0 0 8000
fi
'';
    executable = true;
  };

  # Persistent subscription daemon. `ntfy subscribe --from-config` reads
  # ~/.config/ntfy/client.yml and subscribes to every topic listed under
  # `subscribe:`, invoking the per-topic command on each incoming message.
  # Restart=on-failure matches the unit shipped by the upstream deb package
  # (see ntfy-tablet-setup-2026-07-11 handoff) — if notify-send can't reach
  # a desktop session (e.g. started before login), ntfy retries.
  systemd.user.services.ntfy-client = {
    Unit.Description = "ntfy subscription client";
    Service = {
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy subscribe --from-config";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Forward omp desktop notifications to ntfy topic `omp-linux`.
  #
  # omp detects WezTerm and emits notifications as OSC 9 escape sequences
  # (\x1B]9;); it never calls D-Bus Notify itself (source-verified: omp's
  # pSi() is gated behind notifyProtocol==="\x07"; WezTerm is detected as
  # notifyProtocol="\x1B]9;"). WezTerm bridges OSC 9 to a D-Bus Notify call
  # when its window is unfocused, using WezTerm's OWN app_name, not
  # "Oh My Pi".
  #
  # The jq filter whitelists WezTerm's candidate app_names plus "Oh My Pi"
  # (omp's direct notify-send path on BEL-protocol terminals). Everything
  # else — system daemons (keyboard/headphone connects, battery, network)
  # and our own ntfy popups (app_name "ntfy" via desktop-notify.sh) — is
  # ignored; excluding "ntfy" from the whitelist IS the loop guard.
  # Note: another app inside WezTerm emitting OSC 9 would also forward;
  # omp is the dominant OSC 9 emitter on this machine, so this is accepted.
  home.file.".local/bin/omp-ntfy-forward" = {
    text = ''
#!/usr/bin/env bash
set -euo pipefail

TOPIC="omp-linux"   # dedicated topic chosen by user

busctl monitor --user org.freedesktop.Notifications --json=short \
| ${pkgs.jq}/bin/jq --unbuffered -r \
    'select(.member=="Notify") | .payload.data
     | select(.[0] | IN("wezterm","WezTerm","org.wezfurlong.wezterm","Oh My Pi"))
     | "\(.[3])\t\(.[4])"' \
| while IFS=$'\t' read -r summary body; do
    [ -z "$summary" ] && [ -z "$body" ] && continue
    ${pkgs.ntfy-sh}/bin/ntfy publish "$TOPIC" "''${summary}: ''${body}" || true
  done
'';
    executable = true;
  };

  systemd.user.services.omp-ntfy-forward = {
    Unit = {
      Description = "Forward omp desktop notifications to ntfy";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "/home/bobbytables/.local/bin/omp-ntfy-forward";
      Restart = "always";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
