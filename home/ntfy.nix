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
  xdg.configFile."ntfy/client.yml".text = ''
default-host: https://ntfy.sh

subscribe:
  - topic: shift-automator-doomax
    command: 'notify-send "$title" "$message"'
'';

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
}
