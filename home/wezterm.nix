{ pkgs, ... }:

{
  # The wezterm BINARY comes from pacman (`sudo pacman -S wezterm`), NOT from
  # nixpkgs. On Arch (non-NixOS), nixpkgs wezterm cannot find system GL
  # drivers (libEGL lives in /usr/lib from pacman mesa) → "Failed to create
  # window: with_egl_lib failed"; forcing LD_LIBRARY_PATH=/usr/lib segfaults
  # in libGLdispatch (nix glibc vs Arch libglvnd mismatch). Pacman wezterm
  # links system mesa + system fontconfig directly (fixes fonts too).
  # HM owns only the CONFIG below (wezterm.lua + utils.lua). The niri bind
  # spawns "wezterm" which resolves to /usr/bin/wezterm via PATH.
  programs.wezterm.enable = false;

  xdg.configFile."wezterm/wezterm.lua".text = ''
local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("utils")
local config = wezterm.config_builder()
-- default shell is zsh (user's login shell on Arch)
config.default_prog = { "zsh", "-l" }
-- appearance settings
config.font = wezterm.font_with_fallback({
	"CaskaydiaCove NF",
	"JetBrains Mono",
})
config.enable_kitty_keyboard = true
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.font_size = 10.0
config.adjust_window_size_when_changing_font_size = false
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.color_scheme = "Catppuccin Mocha"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.initial_cols = 120
config.initial_rows = 40
config.window_decorations = "RESIZE"
config.window_frame = {
	border_left_width = 0,
	border_right_width = 0,
	border_bottom_height = 0,
	border_top_height = 0,
}
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32
config.inactive_pane_hsb = {
	saturation = 1,
	brightness = 1,
}
config.colors = {
	compose_cursor = "#94e2d5",
	tab_bar = {
		background = "#1e1e2e",

		active_tab = {
			bg_color = "#585b70",
			fg_color = "#f5e0dc",
			intensity = "Bold",
		},

		inactive_tab = {
			bg_color = "#181825",
			fg_color = "#a6adc8",
		},

		inactive_tab_hover = {
			bg_color = "#313244",
			fg_color = "#cdd6f4",
			italic = true,
		},

		new_tab = {
			bg_color = "#1e1e2e",
			fg_color = "#a6adc8",
		},

		new_tab_hover = {
			bg_color = "#313244",
			fg_color = "#cdd6f4",
			italic = true,
		},
	},
}
config.hyperlink_rules = {
	-- Matches: a URL in parens: (URL)
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in brackets: [URL]
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in curly braces: {URL}
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in angle brackets: <URL>
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
	-- Then handle URLs not wrapped in brackets
	{
		-- Before
		--regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
		--format = '$0',
		-- After
		regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
		format = "$1",
		highlight = 1,
	},
	-- implicit mailto link
	{
		regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
	},
}
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w][-\w\d]+)(/)([-\w\d\.]+)["]?]],
	format = "https://github.com/$1/$3",
})

-- local merged_config = utils.merge_tables(config, local_config) - not used yet, from https://github.com/yutkat/dotfiles/blob/main/.config/wezterm/wezterm.lua

-- show which key table is active in the status area
---@diagnostic disable-next-line: unused-local
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	if name then
		name = "TABLE: " .. name
	elseif window:leader_is_active() then
		name = "LEADER"
	end
	window:set_right_status(name or "")
end)

-- Helper function to move panes between tabs
-- Heuristic: fetches the last 5 lines of pane output and scans backward
-- for a shell prompt line (lines ending with $, #, or > followed by a command).
-- If no prompt marker is found, returns the last non-empty, non-prompt line.
-- Returns the first 40 chars of the identified command.
local function get_pane_last_command(pane_id)
	local success, stdout = wezterm.run_child_process({
		"wezterm",
		"cli",
		"get-text",
		"--pane-id",
		tostring(pane_id),
		"--start-line",
		"-5",
	})
	if not success or not stdout then
		return nil
	end
	local lines = {}
	for line in stdout:gmatch("[^\r\n]+") do
		if line:match("%S") then
			table.insert(lines, line)
		end
	end
	for i = #lines, 1, -1 do
		local line = lines[i]
		local cmd = line:match("[%$#>]%s+(.+)$")
		if cmd then
			return cmd:gsub("^%s+", ""):sub(1, 40)
		end
		if not line:match("^%s*$") and not line:match("^[>%$#]") then
			return line:gsub("^%s+", ""):sub(1, 40)
		end
	end
	return nil
end

local function show_move_pane_selector(window, pane, direction)
	wezterm.log_info("show_move_pane_selector called with direction: " .. direction)

	local direction_map = {
		Left = "left",
		Right = "right",
		Up = "top",
		Down = "bottom",
	}
	local cli_direction = direction_map[direction] or direction:lower()

	local success, stdout, stderr = wezterm.run_child_process({
		"wezterm",
		"cli",
		"list",
		"--format",
		"json",
	})

	wezterm.log_info("list panes success: " .. tostring(success))
	wezterm.log_info("list panes stdout: " .. stdout)

	if not success then
		window:toast_notification("Failed to list panes: " .. (stderr or "unknown error"))
		return
	end

	local panes = wezterm.json_parse(stdout) or {}
	wezterm.log_info("parsed panes count: " .. #panes)
	local choices = {}

	for _, p in ipairs(panes) do
		if p.pane_id ~= pane:pane_id() then
			local _, cwd = utils.split_from_url(p.cwd or "file://")
			local dir_display = utils.convert_home_dir(cwd)
			local size_str = string.format("%dx%d", p.size.cols, p.size.rows)
			local tab_title = p.tab_title or ("Tab " .. p.tab_id)
			local last_cmd = get_pane_last_command(p.pane_id)
			local label
			if last_cmd and last_cmd ~= "" then
				label = string.format("#%d | %s | %s | %s | %s", p.pane_id, tab_title, dir_display, size_str, last_cmd)
			else
				label = string.format(
					"#%d | %s | %s | %s | %s",
					p.pane_id,
					tab_title,
					dir_display,
					size_str,
					p.title or "shell"
				)
			end
			table.insert(choices, {
				id = tostring(p.pane_id),
				label = label,
			})
		end
	end

	if #choices == 0 then
		window:toast_notification("No other panes available to move")
		return
	end

	table.sort(choices, function(a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	wezterm.log_info("Calling InputSelector with " .. #choices .. " choices")
	window:perform_action(
		act.InputSelector({
			title = "Move Pane - Split " .. direction,
			choices = choices,
			fuzzy = true,
			action = wezterm.action_callback(function(inner_window, inner_pane, pane_id)
				if not pane_id then
					return
				end

				local cli_direction = ({
					Up = "top",
					Down = "bottom",
					Left = "left",
					Right = "right",
				})[direction]

				local move_success, move_stdout, move_stderr = wezterm.run_child_process({
					"wezterm",
					"cli",
					"split-pane",
					"--move-pane-id",
					pane_id,
					"--" .. cli_direction,
					"--percent",
					"50",
				})

				if not move_success then
					window:toast_notification("Failed to move pane: " .. (move_stderr or "unknown error"))
				end
			end),
		}),
		pane
	)
end

-- Move pane events
wezterm.on("move-pane-split-left", function(window, pane)
	show_move_pane_selector(window, pane, "Left")
end)

wezterm.on("move-pane-split-down", function(window, pane)
	show_move_pane_selector(window, pane, "Down")
end)

wezterm.on("move-pane-split-up", function(window, pane)
	show_move_pane_selector(window, pane, "Up")
end)

wezterm.on("move-pane-split-right", function(window, pane)
	show_move_pane_selector(window, pane, "Right")
end)

-- Keybinds
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 4294967295 }
-- Main key assignments
config.keys = {
	-- Tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "&", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
	-- Panes
	{
		key = "!",
		mods = "LEADER|SHIFT",
		---@diagnostic disable-next-line: unused-local
		action = wezterm.action_callback(function(win, pane)
			---@diagnostic disable-next-line: unused-local
			local tab, window = pane:move_to_new_tab()
		end),
	},
	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "+", mods = "LEADER|ALT|SHIFT", action = "IncreaseFontSize" },
	{ key = "=", mods = "LEADER|ALT", action = "ResetFontSize" },
	{ key = "-", mods = "LEADER|ALT", action = "DecreaseFontSize" },
	-- launchers
	{ key = "a", mods = "LEADER", action = act.ShowLauncher },
	{ key = "t", mods = "LEADER", action = act.ShowTabNavigator },
	-- Copy mode
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = act.CopyTo("ClipboardAndPrimarySelection") },
	-- Zoom
	{ key = "f", mods = "LEADER", action = act.TogglePaneZoomState },
	-- edit tab name
	{
		key = "e",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of the text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	-- CTRL+Space, followed by 'r' will put us in resize-pane
	-- mode until we cancel that mode.
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
		}),
	},
	-- CTRL+Space followed by 'a' will put us in activate_pane
	-- mode until we press some other key or until 1 second passes
	-- {
	-- 	key = "a",
	-- 	mods = "LEADER",
	-- 	action = act.ActivateKeyTable({
	-- 		name = "activate_pane",
	-- 		timeout_milliseconds = 1000,
	-- 	}),
	-- },
	{
		key = ".", -- Pause Mode
		mods = "LEADER",
		action = act.Multiple({
			act.ScrollByLine(-1),
			act.ActivateCopyMode,
			act.ClearSelection,
		}),
	},
	{
		key = "s",
		mods = "LEADER",
		action = act.PaneSelect({
			alphabet = "1234567890",
		}),
	},
	{
		key = "m",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "move_pane_direction",
			one_shot = false,
		}),
	},
	-- Rotate panes
	{ key = "}", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise") },
	{ key = "{", mods = "LEADER|SHIFT", action = act.RotatePanes("CounterClockwise") },
}

-- Pane resize
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
		-- Esc or leader again to exit leader mode
		{ key = "Space", mods = "CTRL", action = "PopKeyTable" }, -- Exit leader
		{ key = "Escape", action = "PopKeyTable" },
	},
	move_pane_direction = {
		{ key = "h", action = act.EmitEvent("move-pane-split-left") },
		{ key = "j", action = act.EmitEvent("move-pane-split-down") },
		{ key = "k", action = act.EmitEvent("move-pane-split-up") },
		{ key = "l", action = act.EmitEvent("move-pane-split-right") },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Space", mods = "CTRL", action = "PopKeyTable" },
	},
}

return config
'';

  xdg.configFile."wezterm/utils.lua".text = ''
local M = {}

function M.basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.merge_tables(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			M.merge_tables(t1[k], v)
		else
			t1[k] = v
		end
	end
	return t1
end

function M.merge_lists(t1, t2)
	local result = {}
	for _, v in pairs(t1) do
		table.insert(result, v)
	end
	for _, v in pairs(t2) do
		table.insert(result, v)
	end
	return result
end

function M.exists(tab, element)
	for _, v in pairs(tab) do
		if v == element then
			return true
		elseif type(v) == "table" then
			return M.exists(v, element)
		end
	end
	return false
end

function M.convert_home_dir(path)
	local cwd = path
	local home = os.getenv("HOME") or os.getenv("USERPROFILE")
	if home then
		cwd = cwd:gsub("^" .. home .. "/", "~/")
	end
	if cwd == "" then
		return path
	end
	return cwd
end

function M.convert_useful_path(dir)
	local cwd = M.convert_home_dir(dir)
	return M.basename(cwd)
end

function M.split_from_url(dir)
	local cwd = ""
	local hostname = ""
	local cwd_uri = dir:sub(8)
	local slash = cwd_uri:find("/")
	if slash then
		hostname = cwd_uri:sub(1, slash - 1)
		-- Remove the domain name portion of the hostname
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		cwd = cwd_uri:sub(slash)
		cwd = M.convert_useful_path(cwd)
	end
	return hostname, cwd
end

return M
'';
}
