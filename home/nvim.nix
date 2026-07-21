{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # EDITOR / VISUAL are already exported by home/zsh.nix; don't double-set here.
  };

  # libsqlite3.so for sqlite.lua (used by yanky's sqlite ring storage).
  # Declared via HM so the dependency is explicit, not implicit on the system.
  # The path is injected into nvim/lua/_sqlite_path.lua below so sqlite.lua
  # finds it via vim.g.sqlite_clib_path.
  home.packages = [ pkgs.sqlite ];

  # Deploy the full LazyVim config tree to ~/.config/nvim/.
  # recursive = true makes HM symlink each file individually (via lndir) rather
  # than creating a single read-only symlink to the nix store directory. This
  # leaves ~/.config/nvim/ as a real directory that lazy.nvim can write
  # lazy-lock.json into on first run.
  xdg.configFile."nvim" = {
    source = ./nvim-config;
    recursive = true;
  };

  # Generated lua preamble that sets vim.g.sqlite_clib_path for sqlite.lua.
  # Sourced by init.lua via `require("_sqlite_path")` before lazy.nvim.
  # Content is flush-left (column 0) with the closing '' at column 0 so Nix's
  # indented-string stripping leaves the Lua bytes untouched — matches the
  # wezterm.nix convention documented in the #5 handoff.
  xdg.configFile."nvim/lua/_sqlite_path.lua".text = ''
-- Set vim.g.sqlite_clib_path for sqlite.lua (yanky's sqlite ring storage).
-- Probes the HM-provided sqlite first (always present after switch), then
-- common system paths. First readable wins; if none match, sqlite.lua
-- falls back to its own ffi.C lookup.
local candidates = {
  "${pkgs.sqlite.out}/lib/libsqlite3.so",
  "/usr/lib/libsqlite3.so",
  "/usr/lib/x86_64-linux-gnu/libsqlite3.so",
  "/lib64/libsqlite3.so",
  "/usr/lib64/libsqlite3.so",
}
for _, p in ipairs(candidates) do
  if vim.fn.filereadable(p) == 1 then
    vim.g.sqlite_clib_path = p
    break
  end
end
'';
}
