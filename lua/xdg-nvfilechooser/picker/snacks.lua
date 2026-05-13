--- @class xdg.DirPickerConfig
--- @field title string
--- @field cwd string
--- @field relative? string
--- @field multiple? boolean
--- @field keymaps? table<string, xdg.KeyMapping|nil>
--- @field on_confirm? fun(picker: snacks.picker.Picker)

--- @class xdg.PickerItem
--- @field text string
--- @field file? string
--- @field _path? string
--- @field score? number

local M = {}

local util = require("xdg-nvfilechooser.util")

--- @param item xdg.PickerItem
--- @return snacks.picker.Entry[]
local function _format_directory(item)
	local snacks = require("snacks")
	if item._path then
		item.file = item._path
	end
	local icon, hl = snacks.util.icon("", "directory")
	return {
		{ icon .. " ", hl },
		{ item.text },
	}
end

--- @param output_path string
--- @param selected xdg.PickerItem[]
local function _write_output(output_path, selected)
	local f = io.open(output_path, "w")
	if not f then
		vim.notify("Failed to write output to " .. output_path, vim.log.levels.ERROR)
		return
	end
	for _, item in ipairs(selected) do
		f:write(item.file .. "\n")
	end
	f:close()
end

--- @return fun(picker: snacks.picker.Picker)
local function _build_goto_path_action()
	return function(picker)
		vim.ui.input({ prompt = "Go to path: " }, function(input)
			if not input or input == "" then
				return
			end
			input = vim.fn.expand(input)
			picker.opts.cwd = input
			picker.opts.dirs = { input }
			picker:find()
		end)
	end
end

--- @param multiple boolean|nil
--- @return {select_next: fun(picker: snacks.picker.Picker), select_prev: fun(picker: snacks.picker.Picker), sel_all: fun(picker: snacks.picker.Picker)}
local function _build_multi_actions(multiple)
	return {
		select_next = function(picker)
			if not multiple and picker:count() > 0 then
				vim.notify("Max 1 selection")
				return
			end
			picker:action("select_and_next")
		end,
		select_prev = function(picker)
			if not multiple and picker:count() > 0 then
				vim.notify("Max 1 selection")
				return
			end
			picker:action("select_and_prev")
		end,
		sel_all = function(picker)
			if not multiple and picker:count() > 0 then
				vim.notify("Max 1 selection")
				return
			end
			picker:action("select_all")
		end,
	}
end

-- Credits for directories picker:
-- https://github.com/folke/snacks.nvim/issues/1036#issuecomment-3959884371
--- @param config xdg.DirPickerConfig
local function _show_directory_picker(config)
	local cmd, args = util.directory_finder()
	if not cmd then
		vim.notify("No supported finder found (fd/fdfind)", vim.log.levels.ERROR)
		return
	end

	local multi_actions = _build_multi_actions(config.multiple)

	require("snacks").picker.pick({
		title = config.title,
		cwd = config.cwd,
		dirs = { config.cwd },
		pattern = config.relative,
		format = _format_directory,
		transform = function(item, _)
			item._path = vim.fs.abspath(item.text)
			item.file = item._path
			if config.relative and item.text == config.relative then
				item.score = math.huge
			end
			return item
		end,
		finder = function(opts2, ctx)
			return require("snacks.picker.source.proc").proc(
				vim.tbl_extend("force", opts2, { cmd = cmd, args = args }),
				ctx
			)
		end,
		actions = {
			confirm = config.on_confirm or function()
				vim.notify("No confirm action configured", vim.log.levels.ERROR)
			end,
			goto_path = _build_goto_path_action(),
			select_next = multi_actions.select_next,
			select_prev = multi_actions.select_prev,
			sel_all = multi_actions.sel_all,
		},
		win = util.build_keymaps(config.keymaps),
	})
end

--- @param opts xdg.Opts
--- @param keymaps? table<string, xdg.KeyMapping|nil>
function M.open_files(opts, keymaps)
	local exts = util.build_ext_filters(opts.filters)

	require("snacks").picker.files({
		title = opts.multiple and "Multi-file selection" or "Single-file selection",
		cwd = opts.current_folder or "",
		dirs = { vim.fn.expand("~") },
		matcher = {
			cwd_bonus = opts.current_folder and true or false,
			sort_empty = opts.current_folder and true or false,
		},
		transform = function(item, _)
			if #exts > 0 then
				if not item.file then
					return true
				end
				local item_ext = item.file:match("%.([^%.]+)$")
				if not item_ext then
					return false
				end
				item_ext = item_ext:lower()
				for _, ext in ipairs(exts) do
					if item_ext == ext then
						return true
					end
				end
				return false
			end
			return true
		end,
		actions = {
			confirm = function(picker)
				local selected = picker:selected({ fallback = true })
				if not opts.multiple then
					selected = { selected[1] }
				end
				_write_output(opts.output, selected)
				picker:close()
				vim.cmd("qa!")
			end,
			goto_path = _build_goto_path_action(),
			select_next = function(picker)
				if not opts.multiple and picker:count() > 0 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_and_next")
			end,
			select_prev = function(picker)
				if not opts.multiple and picker:count() > 0 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_and_prev")
			end,
			sel_all = function(picker)
				if not opts.multiple and picker:count() > 0 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_all")
			end,
		},
		win = util.build_keymaps(keymaps),
	})
end

--- @param opts xdg.Opts
--- @param keymaps? table<string, xdg.KeyMapping|nil>
function M.open_directories(opts, keymaps)
	_show_directory_picker({
		title = opts.multiple and "Multi-directory selection" or "Single-directory selection",
		cwd = vim.fn.expand("~"),
		multiple = opts.multiple,
		keymaps = keymaps,
		on_confirm = function(picker)
			local selected = picker:selected({ fallback = true })
			if not opts.multiple then
				selected = { selected[1] }
			end
			_write_output(opts.output, selected)
			picker:close()
			vim.cmd("qa!")
		end,
	})
end

--- @param opts xdg.Opts
--- @param keymaps? table<string, xdg.KeyMapping|nil>
function M.save_file(opts, keymaps)
	local base, relative = util.resolve_base_relative(opts.current_folder)

	_show_directory_picker({
		title = "Save File",
		cwd = base,
		relative = relative,
		multiple = false,
		keymaps = keymaps,
		on_confirm = function(picker)
			local selected = picker:selected({ fallback = true })
			if not selected or #selected == 0 then
				return
			end
			picker:close()

			vim.ui.input({ prompt = "Save as: ", default = opts.current_name or "" }, function(input)
				if not input or input == "" then
					return
				end
				local f = io.open(opts.output, "w")
				if f then
					local full = vim.fs.joinpath(base, selected[1].text, input)
					f:write(full .. "\n")
					f:close()
				end
				vim.cmd("qa!")
			end)
		end,
	})
end

--- @param opts xdg.Opts
--- @param keymaps? table<string, xdg.KeyMapping|nil>
function M.save_files(opts, keymaps)
	local base, relative = util.resolve_base_relative(opts.current_folder)

	_show_directory_picker({
		title = "Select Destination Directory",
		cwd = base,
		relative = relative,
		multiple = false,
		keymaps = keymaps,
		on_confirm = function(picker)
			local selected = picker:selected({ fallback = true })
			if not selected or #selected == 0 then
				return
			end
			local dir = vim.fs.joinpath(base, selected[1].text)
			local f = io.open(opts.output, "w")
			if f then
				f:write(dir .. "\n")
				f:close()
			end
			picker:close()
			vim.cmd("qa!")
		end,
	})
end

return M
