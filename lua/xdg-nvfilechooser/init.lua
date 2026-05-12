local M = {}

function M.setup(opts)
	M.picker = opts.picker
end

local pickers = {
	snacks = require("xdg-nvfilechooser.snacks"),
	-- TODO:
	-- telescope = require("xdg-nvfilechooser.telescope"),
	-- fzf_lua = require("xdg-nvfilechooser.fzf_lua"),
}

function M.OpenFile(opts)
	return pickers[M.picker].open(opts)
end

function M.SaveFile(opts)
	return pickers[M.picker].save(opts)
end

function M.SaveFiles(opts)
	return pickers[M.picker].save_files(opts)
end

return M
