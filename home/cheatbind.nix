{
  lib,
  python3,
  fetchPypi,
  gtk4,
  gtk4-layer-shell,
  pango,
  harfbuzz,
  gdk-pixbuf,
  graphene,
  gobject-introspection,
  wrapGAppsHook4,
}:

# cheatbind — Wayland keybinding cheatsheet overlay (parses niri config.kdl,
# renders a styled multi-column GTK popup). Upstream is PyPI-only (no nixpkgs
# package, no upstream flake), so this inline derivation fetches the 0.2.0 sdist
# and builds it as a proper nix package — matching which-key-wayland's
# declarative install channel (see flake.nix overlay + niri-extras.nix).
#
# Runtime dep is just PyGObject (GTK4 binding); the GTK4 C stack (gtk4,
# gtk4-layer-shell, pango, harfbuzz, gdk-pixbuf, graphene) is provided via
# buildInputs. None of these self-export GI_TYPELIB_PATH (no nix-support
# setup-hook on any of them), so wrapGAppsHook4's auto-discovery finds only
# glib + gobject-introspection and PyGObject fails at runtime with
# `Namespace Gdk not available`. The preFixup phase below mates the GTK4
# typelib closure into `gappsWrapperArgs` (the bash array wrapGApps reads
# when it wraps, later inside fixupPhase) so every Gdk-4.0 / Gtk-4.0 /
# Gtk4LayerShell-1.0 / PangoCairo-1.0 / Graphene-1.0 namespace resolves.
#
# Triggered by niri bind `Mod+Shift+Slash { spawn "cheatbind"; }` in niri.nix.
# Style override: ~/.config/cheatbind/style.css (xdg.configFile in niri-extras.nix).

python3.pkgs.buildPythonApplication rec {
  pname = "cheatbind";
  version = "0.2.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    sha256 = "accce14202bf38de4ad38217e975b773d178d311759ea49db17d04ebc5f39c40";
  };
  # cheatbind's _init_gtk() explicitly CDLL-preloads libgtk4-layer-shell.so
  # before importing gi.repository (necessary so the layer-shell shim loads
  # before libwayland-client, per gtk4-layer-shell's linking.md). However the
  # upstream source hardcodes "/usr/lib/libgtk4-layer-shell.so", which does
  # not exist under a Nix install (the lib lives in the nix store). Without
  # this patch the preload silently no-ops and the overlay fails to become a
  # layer surface — niri never sees it. Substitute the actual nix store path
  # so the CDLL call resolves at runtime.
  postPatch = ''
    substituteInPlace src/cheatbind/main.py \
      --replace-fail \
        '/usr/lib/libgtk4-layer-shell.so' \
        '${lib.getLib gtk4-layer-shell}/lib/libgtk4-layer-shell.so'
  '';

  # PyGObject>=3.46 from nixpkgs pythonPackages — sole runtime dep per pyproject.
  propagatedBuildInputs = [
    python3.pkgs.pygobject3
  ];

  # cheatbind requires Gdk 4.0, Gtk 4.0, Gtk4LayerShell 1.0, plus their transitive
  # typelib namespaces (PangoCairo 1.0, GdkPixbuf 2.0, HarfBuzz 0.0, Graphene 1.0).
  #
  # lib.getLib selects each package's `out` output — the multi-output resolution
  # for buildInputs defaults to `dev`, but the .typelib files live in
  # `out/lib/girepository-1.0`, so we must pin to the lib output here or the
  # preFixup walk below sees only dev outputs (which ship no typelibs).
  buildInputs = [
    (lib.getLib gtk4)
    (lib.getLib gtk4-layer-shell)
    (lib.getLib pango)
    (lib.getLib harfbuzz)
    (lib.getLib gdk-pixbuf)
    (lib.getLib graphene)
    (lib.getLib gobject-introspection)
  ];

  nativeBuildInputs = [
    wrapGAppsHook4
    # pyproject = true builds via PEP517 (--no-isolation); the sdist declares
    # build-system setuptools>=68.0 — supply it explicitly so the build env
    # can import `setuptools.build_meta`.
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  # Phase ordering in stdenv: gappsWrapperArgsHook (in preFixupPhases) builds
  # the `gappsWrapperArgs` bash array, then fixupPhase runs the `preFixup`
  # script, then wrapGApps wraps the binaries using that array. None of the
  # gtk4-stack packages self-export GI_TYPELIB_PATH, so the hook finds only
  # glib + gobject-introspection by default. Append our typelib closure
  # directly to the array here — bash arrays survive across commands within
  # the same phase, and wrapGApps (which runs after preFixup inside
  # fixupPhase) picks up the augmented array. Exporting the env var alone
  # would be too late — the hook already snapshotted it earlier.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix
      GI_TYPELIB_PATH
      :
      "$(
        for d in $buildInputs $propagatedBuildInputs; do
          if [ -d "$d/lib/girepository-1.0" ]; then
            printf '%s:' "$d/lib/girepository-1.0"
          fi
        done
      )"
    )
  '';

  # No test suite shipped in the sdist — disable the check phase.
  doCheck = false;

  meta = with lib; {
    description = "Wayland keyboard shortcuts overlay — parses compositor config and displays a styled cheatsheet";
    homepage = "https://github.com/Xhelliom/cheatbind";
    license = licenses.mit;
    mainProgram = "cheatbind";
  };
}