local M = {}

local mime_to_exts = {
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

local function directory_finder()
	if vim.fn.executable("fd") == 1 then
		return "fd", { ".", "--type", "directory" }
	end

	if vim.fn.executable("fdfind") == 1 then
		return "fdfind", { ".", "--type", "directory" }
	end

	return nil, nil
end

function M.open(opts)
	-- Credits for directories:
	-- https://github.com/folke/snacks.nvim/issues/1036#issuecomment-3959884371
	if opts.directory then
		require("snacks").picker.pick({
			title = opts.multiple and "Multi-directory selection" or "Single-directory selection",
			format = function(item, picker)
				local snacks = require("snacks")
				if item._path then
					item.file = item._path
				end
				local icon, hl = snacks.util.icon("", "directory")

				return {
					{ icon .. " ", hl },
					{ item.text },
				}
			end,
			finder = function(opts2, ctx)
				local cmd, args = directory_finder()

				if not cmd then
					vim.notify("No supported finder found (fd/fdfind)", vim.log.levels.ERROR)
					return
				end

				return require("snacks.picker.source.proc").proc(
					vim.tbl_extend("force", opts2, {
						cmd = cmd,
						args = args,
					}),
					ctx
				)
			end,
			transform = function(item, _)
				item._path = vim.fs.abspath(item.text)
				item.file = item._path
				return item
			end,
			actions = {
				select_next = function(picker, _)
					if not opts.multiple and picker:count() > 1 then
						vim.notify("Max 1 selection")
						return
					end
					picker:action("select_and_next")
				end,
				select_prev = function(picker, _)
					if not opts.multiple and picker:count() > 1 then
						vim.notify("Max 1 selection")
						return
					end
					picker:action("select_and_prev")
				end,
				confirm = function(picker)
					local selected = picker:selected({ fallback = true })
					local f = io.open(opts.output, "w")
					if f then
						for _, item in ipairs(selected) do
							f:write(item.file .. "\n")
						end
						f:close()
					end
					picker:close()
					vim.cmd("qa!")
				end,

				goto_path = function(picker)
					vim.ui.input({ prompt = "Go to path: " }, function(input)
						if not input or input == "" then
							return
						end

						input = vim.fn.expand(input)
						picker.opts.cwd = input
						picker.opts.dirs = { input }

						picker:find()
					end)
				end,

				sel_all = function(picker)
					if not opts.multiple and picker:count() > 1 then
						vim.notify("Max 1 selection")
						return
					end
					picker:action("select_all")
				end,
			},
			win = {
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
			},
		})
		return
	end

	local function glob_to_ext(glob)
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

	local exts = {}

	for _, filter in ipairs(opts.filters or {}) do
		for _, glob in ipairs(filter.globs or {}) do
			if glob.kind == 0 then
				local ext = glob_to_ext(glob.pattern)
				if ext then
					table.insert(exts, ext)
				end
			elseif glob.kind == 1 then
				local mapped = mime_to_exts[glob.pattern]
				if mapped then
					for _, ext in ipairs(mapped) do
						table.insert(exts, ext)
					end
				end
			end
		end
	end

	require("snacks").picker.files({
		title = opts.multiple and "Multi-file selection" or "Single-file selection",

		format = function(item, picker)
			local snacks = require("snacks")
			if item._path then
				item.file = item._path
			end
			return snacks.picker.format.file(item, picker)
		end,

		cwd = opts.current_folder or "",

		dirs = {
			vim.fn.expand("~"),
		},

		-- gives boost to files that are contained in the "current_folder" option if
		-- set by xdg desktop portal client but still returns all files from the home directory.
		matcher = {
			cwd_bonus = opts.current_folder and true or false,
			sort_empty = opts.current_folder and true or false,
		},

		transform = function(item, _)
			if #exts == 0 then
				return true
			end
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
		end,
		actions = {
			-- in the rare case a user wants to select a file in /etc for exampl.e
			goto_path = function(picker)
				vim.ui.input({ prompt = "Go to path: " }, function(input)
					if not input or input == "" then
						return
					end

					input = vim.fn.expand(input)
					picker.opts.cwd = input
					picker.opts.dirs = { input }

					picker:find()
				end)
			end,
			confirm = function(picker)
				local selected = picker:selected({ fallback = true })
				local f = io.open(opts.output, "w")
				if f then
					for _, item in ipairs(selected) do
						f:write(item._path .. "\n")
					end
					f:close()
				end
				picker:close()
				vim.cmd("qa!")
			end,

			select_prev = function(picker)
				if not opts.multiple and picker:count() > 1 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_and_prev")
			end,
			select_next = function(picker)
				if not opts.multiple and picker:count() > 1 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_and_next")
			end,
			sel_all = function(picker)
				if not opts.multiple and picker:count() > 1 then
					vim.notify("Max 1 selection")
					return
				end
				picker:action("select_all")
			end,
		},
		win = {
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
		},
	})
end

function M.save(opts)
	local current_folder = opts.current_folder
	local base, relative

	if current_folder then
		local home = vim.fn.expand("~")
		if current_folder == home then
			base = home
			relative = nil
		elseif current_folder:sub(1, #home) == home then
			base = home
			relative = current_folder:gsub("^" .. vim.pesc(home) .. "/", "")
		else
			base = "/"
			relative = vim.fn.fnamemodify(current_folder, ":t")
		end
	else
		base = vim.fn.expand("~")
		relative = nil
	end

	require("snacks").picker.pick({
		title = "Save File",
		cwd = base,
		dirs = { base },
		format = function(item, _)
			local icon, hl = require("snacks").util.icon("", "directory")
			return {
				{ icon .. " ", hl },
				{ item.text },
			}
		end,
		pattern = relative,
		transform = function(item, _)
			item.file = item.text
			if relative and item.text == relative then
				item.score = math.huge
			end
			return item
		end,

		finder = function(opts2, ctx)
			local cmd, args = directory_finder()
			if not cmd then
				vim.notify("No supported finder found (fd/fdfind)", vim.log.levels.ERROR)
				return
			end
			return require("snacks.picker.source.proc").proc(
				vim.tbl_extend("force", opts2, { cmd = cmd, args = args }),
				ctx
			)
		end,
		actions = {
			confirm = function(picker)
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
			goto_path = function(picker)
				vim.ui.input({ prompt = "Go to path: " }, function(input)
					if not input or input == "" then
						return
					end
					input = vim.fn.expand(input)
					picker.opts.cwd = input
					picker.opts.dirs = { input }
					picker:find()
				end)
			end,
			select_prev = function()
				vim.notify("Max 1 selection")
			end,
			select_next = function()
				vim.notify("Max 1 selection")
			end,
			sel_all = function()
				vim.notify("Max 1 selection")
			end,
		},
		win = {
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
		},
	})
end

function M.save_files(opts)
	local current_folder = opts.current_folder
	local base, relative

	if current_folder then
		local home = vim.fn.expand("~")
		if current_folder == home then
			base = home
			relative = nil
		elseif current_folder:sub(1, #home) == home then
			base = home
			relative = current_folder:gsub("^" .. vim.pesc(home) .. "/", "")
		else
			base = "/"
			relative = vim.fn.fnamemodify(current_folder, ":t")
		end
	else
		base = vim.fn.expand("~")
		relative = nil
	end

	local picker_opts = {
		title = "Select Destination Directory",
		cwd = base,
		dirs = { base },
		format = function(item, _)
			local icon, hl = require("snacks").util.icon("", "directory")
			return {
				{ icon .. " ", hl },
				{ item.text },
			}
		end,
		finder = function(opts2, ctx)
			local cmd, args = directory_finder()
			if not cmd then
				vim.notify("No supported finder found (fd/fdfind)", vim.log.levels.ERROR)
				return
			end
			return require("snacks.picker.source.proc").proc(
				vim.tbl_extend("force", opts2, { cmd = cmd, args = args }),
				ctx
			)
		end,
		transform = function(item, _)
			item.file = item.text
			if relative and item.text == relative then
				item.score = math.huge
			end
			return item
		end,
		actions = {
			confirm = function(picker)
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
			goto_path = function(picker)
				vim.ui.input({ prompt = "Go to path: " }, function(input)
					if not input or input == "" then
						return
					end
					input = vim.fn.expand(input)
					picker.opts.cwd = input
					picker.opts.dirs = { input }
					picker:find()
				end)
			end,
			select_prev = function()
				vim.notify("Max 1 selection")
			end,
			select_next = function()
				vim.notify("Max 1 selection")
			end,
			sel_all = function()
				vim.notify("Max 1 selection")
			end,
		},
		win = {
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
		},
	}

	if relative then
		picker_opts.pattern = relative
	end

	require("snacks").picker.pick(picker_opts)
end

return M
