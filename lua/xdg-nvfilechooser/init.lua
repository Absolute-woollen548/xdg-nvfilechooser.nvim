--- @class xdg.Opts
--- @field output string
--- @field directory? boolean
--- @field multiple? boolean
--- @field current_folder? string
--- @field current_name? string
--- @field filters? xdg.Filter[]

--- @class xdg.SetupOpts
--- @field picker? string
--- @field keymaps? table<string, xdg.KeyMapping|nil>

local M = {}
local _config

--- @param opts xdg.SetupOpts
function M.setup(opts)
	_config = opts
end

local function _picker()
	local Picker = require("xdg-nvfilechooser.picker")
	local p = Picker.new(_config and _config.picker or "snacks")
	if _config and _config.keymaps then
		p.keymaps = _config.keymaps
	end
	return p
end

--- @param opts xdg.Opts
function M.OpenFile(opts)
	local p = _picker()
	if opts.directory then
		p:open_directories(opts)
	else
		p:open_files(opts)
	end
end

--- @param opts xdg.Opts
function M.SaveFile(opts)
	_picker():save_file(opts)
end

--- @param opts xdg.Opts
function M.SaveFiles(opts)
	_picker():save_files(opts)
end

return M
