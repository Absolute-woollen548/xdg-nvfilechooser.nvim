--- @class xdg.PickerBackend
--- @field open_files fun(opts: xdg.Opts, keymaps?: table<string, xdg.KeyMapping|nil>)
--- @field open_directories fun(opts: xdg.Opts, keymaps?: table<string, xdg.KeyMapping|nil>)
--- @field save_file fun(opts: xdg.Opts, keymaps?: table<string, xdg.KeyMapping|nil>)
--- @field save_files fun(opts: xdg.Opts, keymaps?: table<string, xdg.KeyMapping|nil>)

--- @class xdg.Picker
--- @field impl xdg.PickerBackend
--- @field keymaps? table<string, xdg.KeyMapping|nil>

local backends = {
	snacks = require("xdg-nvfilechooser.picker.snacks"),
}

local Picker = {}
Picker.__index = Picker

--- @param name string|nil
--- @return xdg.Picker
function Picker.new(name)
	name = name or "snacks"
	local impl = backends[name]
	if not impl then
		vim.notify("Unknown picker backend '" .. name .. "', falling back to snacks", vim.log.levels.WARN)
		impl = backends.snacks
	end
	return setmetatable({ impl = impl }, Picker)
end

--- @param opts xdg.Opts
function Picker:open_files(opts)
	return self.impl.open_files(opts, self.keymaps)
end

--- @param opts xdg.Opts
function Picker:open_directories(opts)
	return self.impl.open_directories(opts, self.keymaps)
end

--- @param opts xdg.Opts
function Picker:save_file(opts)
	return self.impl.save_file(opts, self.keymaps)
end

--- @param opts xdg.Opts
function Picker:save_files(opts)
	return self.impl.save_files(opts, self.keymaps)
end

return Picker
