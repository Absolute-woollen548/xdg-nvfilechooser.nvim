--- @class xdg.Glob
--- @field kind 0|1
--- @field pattern string

--- @class xdg.Filter
--- @field globs xdg.Glob[]

--- @alias xdg.KeyMapping {[1]: string, mode: string[]}

--- @class xdg.KeymapTable
--- @field input {keys: table<string, xdg.KeyMapping>}

local M = {}

M.mime_to_exts = {
	["text/plain"] = { "txt", "text", "log" },
	["text/html"] = { "html", "htm" },
	["text/css"] = { "css" },
	["text/csv"] = { "csv" },
	["text/xml"] = { "xml" },
	["text/markdown"] = { "md", "markdown" },
	["image/jpeg"] = { "jpg", "jpeg" },
	["image/png"] = { "png" },
	["image/gif"] = { "gif" },
	["image/webp"] = { "webp" },
	["image/svg+xml"] = { "svg" },
	["image/ico"] = { "ico" },
	["audio/mpeg"] = { "mp3" },
	["audio/ogg"] = { "ogg" },
	["audio/wav"] = { "wav" },
	["audio/flac"] = { "flac" },
	["video/mp4"] = { "mp4" },
	["video/webm"] = { "webm" },
	["video/x-msvideo"] = { "avi" },
	["video/quicktime"] = { "mov" },
	["video/x-matroska"] = { "mkv" },
	["application/pdf"] = { "pdf" },
	["application/msword"] = { "doc" },
	["application/vnd.openxmlformats-officedocument.wordprocessingml.document"] = { "docx" },
	["application/vnd.ms-excel"] = { "xls" },
	["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] = { "xlsx" },
	["application/vnd.ms-powerpoint"] = { "ppt" },
	["application/vnd.openxmlformats-officedocument.presentationml.presentation"] = { "pptx" },
	["application/zip"] = { "zip" },
	["application/gzip"] = { "gz", "tgz" },
	["application/x-tar"] = { "tar" },
	["application/x-7z-compressed"] = { "7z" },
	["application/x-rar-compressed"] = { "rar" },
	["application/json"] = { "json" },
	["application/javascript"] = { "js" },
	["application/typescript"] = { "ts" },
	["application/xml"] = { "xml" },
	["application/wasm"] = { "wasm" },
	["font/ttf"] = { "ttf" },
	["font/woff"] = { "woff" },
	["font/woff2"] = { "woff2" },
}

--- @param glob string
--- @return string|nil
function M.glob_to_ext(glob)
	local ext = glob:match("%.([^%.]+)$")
	if not ext then
		return nil
	end
	ext = ext:gsub("%[(%a)%a%]", function(c)
		return c:lower()
	end)
	if ext:match("%*") then
		return nil
	end
	return ext
end

--- @param filters xdg.Filter[]|nil
--- @return string[]
function M.build_ext_filters(filters)
	local exts = {}
	for _, filter in ipairs(filters or {}) do
		for _, g in ipairs(filter.globs or {}) do
			if g.kind == 0 then
				local ext = M.glob_to_ext(g.pattern)
				if ext then
					table.insert(exts, ext)
				end
			elseif g.kind == 1 then
				local mapped = M.mime_to_exts[g.pattern]
				if mapped then
					for _, ext in ipairs(mapped) do
						table.insert(exts, ext)
					end
				end
			end
		end
	end
	return exts
end

--- @return string|nil, string[]|nil
function M.directory_finder()
	if vim.fn.executable("fd") == 1 then
		return "fd", { ".", "--type", "directory" }
	end
	if vim.fn.executable("fdfind") == 1 then
		return "fdfind", { ".", "--type", "directory" }
	end
	return nil, nil
end

--- @param current_folder string|nil
--- @return string, string|nil
function M.resolve_base_relative(current_folder)
	if not current_folder then
		return vim.fn.expand("~"), nil
	end
	local home = vim.fn.expand("~")
	if current_folder == home then
		return home, nil
	end
	if current_folder:sub(1, #home) == home then
		return home, current_folder:gsub("^" .. vim.pesc(home) .. "/", "")
	end
	return "/", vim.fn.fnamemodify(current_folder, ":t")
end

--- @param overrides table<string, xdg.KeyMapping|nil>|nil
--- @return xdg.KeymapTable
function M.build_keymaps(overrides)
	local keymaps = {
		input = {
			keys = {
				["<C-e>"] = { "goto_path", mode = { "n", "i" } },
				["<CR>"] = { "confirm", mode = { "n", "i" } },
				["<S-CR>"] = { "confirm", mode = { "n", "i" } },
				["<Tab>"] = { "select_next", mode = { "n", "i" } },
				["<S-Tab>"] = { "select_prev", mode = { "n", "x" } },
				["<C-a>"] = { "sel_all", mode = { "n", "i" } },
			},
		},
	}

	if overrides then
		for key, mapping in pairs(overrides) do
			keymaps.input.keys[key] = mapping
		end
	end

	return keymaps
end

return M
