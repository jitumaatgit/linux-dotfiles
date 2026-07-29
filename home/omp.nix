{ config, pkgs, ... }:

{
  # oh-my-pi (omp) TUI configuration.
  #
  # omp reads user keybinding remaps from ~/.omp/agent/keybindings.yml — a flat
  # YAML map of action ID -> chord string (or array of chord strings). It is NOT
  # part of ~/.omp/agent/config.yml and there is no nested `keybindings` object.
  # Run `/hotkeys` inside an omp session to see the active chords.
  # Authoritative action IDs + override-file semantics: omp://keybindings.md.
  #
  # The file below is managed by home-manager (symlink into the nix store). Do
  # NOT edit ~/.omp/agent/keybindings.yml directly — edit this module and run
  # `home-manager switch`.
  home.file.".omp/agent/keybindings.yml".text = ''
    # Open the prompt draft in nvim via `$VISUAL` / `$EDITOR`.
    # `Ctrl+G` is the documented default — kept explicitly so muscle memory still
    # works and the user remap is unambiguous (user remaps win over defaults).
    # `Alt+V` is a vim-flavored alias ("V" for editor). On Linux it is not a
    # documented default for any action (the `Alt+V` paste fallback is Windows-only;
    # `app.clipboard.pasteImage` defaults to `Ctrl+V` here), so it is safe to claim.
    app.editor.external:
      - Ctrl+G
      - Alt+V
  '';
}
