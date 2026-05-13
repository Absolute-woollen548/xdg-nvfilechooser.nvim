local util = require("xdg-nvfilechooser.util")

describe("util", function()
	describe("glob_to_ext", function()
		it("extracts simple extension", function()
			assert.are.equal("txt", util.glob_to_ext("*.txt"))
		end)

		it("extracts only last extension segment", function()
			assert.are.equal("gz", util.glob_to_ext("*.tar.gz"))
		end)

		it("returns nil for pattern without extension", function()
			assert.is_nil(util.glob_to_ext("Makefile"))
		end)

		it("handles character class globs", function()
			assert.are.equal("jpg", util.glob_to_ext("*.[Jj][Pp][Gg]"))
		end)

		it("returns nil for wildcard extension", function()
			assert.is_nil(util.glob_to_ext("*.*"))
		end)

		it("does not handle brace expansion patterns", function()
			assert.are.equal("{txt,md}", util.glob_to_ext("*.{txt,md}"))
		end)

		it("returns nil for pattern with no dot", function()
			assert.is_nil(util.glob_to_ext("README"))
		end)
	end)

	describe("build_ext_filters", function()
		it("returns empty table for nil filters", function()
			assert.are.same({}, util.build_ext_filters(nil))
		end)

		it("returns empty table for empty filters", function()
			assert.are.same({}, util.build_ext_filters({}))
		end)

		it("returns empty table for filter with no globs", function()
			assert.are.same({}, util.build_ext_filters({ {} }))
		end)

		it("extracts from glob kind 0", function()
			local filters = { { globs = { { kind = 0, pattern = "*.txt" } } } }
			assert.are.same({ "txt" }, util.build_ext_filters(filters))
		end)

		it("maps mime types (kind 1)", function()
			local filters = { { globs = { { kind = 1, pattern = "image/png" } } } }
			assert.are.same({ "png" }, util.build_ext_filters(filters))
		end)

		it("combines glob and mime filters", function()
			local filters = {
				{
					globs = {
						{ kind = 0, pattern = "*.txt" },
						{ kind = 1, pattern = "image/png" },
					},
				},
			}
			assert.are.same({ "txt", "png" }, util.build_ext_filters(filters))
		end)

		it("handles unknown mime type gracefully", function()
			local filters = { { globs = { { kind = 1, pattern = "application/x-unknown" } } } }
			assert.are.same({}, util.build_ext_filters(filters))
		end)

		it("skips globs that don't map to an extension", function()
			local filters = { { globs = { { kind = 0, pattern = "Makefile" } } } }
			assert.are.same({}, util.build_ext_filters(filters))
		end)

		it("handles multiple filters", function()
			local filters = {
				{ globs = { { kind = 0, pattern = "*.txt" } } },
				{ globs = { { kind = 1, pattern = "image/png" } } },
			}
			assert.are.same({ "txt", "png" }, util.build_ext_filters(filters))
		end)
	end)

	describe("resolve_base_relative", function()
		it("returns home and nil when current_folder is nil", function()
			local base, relative = util.resolve_base_relative(nil)
			assert.are.equal(vim.fn.expand("~"), base)
			assert.is_nil(relative)
		end)

		it("returns home and nil when current_folder is home", function()
			local home = vim.fn.expand("~")
			local base, relative = util.resolve_base_relative(home)
			assert.are.equal(home, base)
			assert.is_nil(relative)
		end)

		it("resolves subdirectory of home", function()
			local home = vim.fn.expand("~")
			local base, relative = util.resolve_base_relative(home .. "/Documents")
			assert.are.equal(home, base)
			assert.are.equal("Documents", relative)
		end)

		it("resolves nested subdirectory of home", function()
			local home = vim.fn.expand("~")
			local base, relative = util.resolve_base_relative(home .. "/projects/work")
			assert.are.equal(home, base)
			assert.are.equal("projects/work", relative)
		end)

		it("uses root as base for paths outside home", function()
			local base, relative = util.resolve_base_relative("/etc/nginx")
			assert.are.equal("/", base)
			assert.is_not_nil(relative)
		end)

		it("trailing slash does not break path matching", function()
			local home = vim.fn.expand("~")
			local base, relative = util.resolve_base_relative(home .. "/Documents/")
			assert.are.equal(home, base)
		end)
	end)

	describe("directory_finder", function()
		it("returns a known finder (fd or fdfind) or nil", function()
			local cmd, args = util.directory_finder()
			if cmd then
				assert.is_true(
					vim.fn.executable(cmd) == 1,
					"finder command must be executable: " .. cmd
				)
				assert.are.same({ ".", "--type", "directory" }, args)
			else
				assert.is_nil(args)
			end
		end)
	end)

	describe("build_keymaps", function()
		it("returns a table with input.keys", function()
			local keys = util.build_keymaps()
			assert.is_not_nil(keys.input)
			assert.is_not_nil(keys.input.keys)
		end)

		it("contains all expected keybindings", function()
			local keys = util.build_keymaps().input.keys
			assert.is_not_nil(keys["<C-e>"])
			assert.is_not_nil(keys["<CR>"])
			assert.is_not_nil(keys["<S-CR>"])
			assert.is_not_nil(keys["<Tab>"])
			assert.is_not_nil(keys["<S-Tab>"])
			assert.is_not_nil(keys["<C-a>"])
		end)

		it("maps all keys to valid actions", function()
			local keys = util.build_keymaps().input.keys
			for key, mapping in pairs(keys) do
				assert.is_string(mapping[1], "action for " .. key .. " should be a string")
				assert.is_not_nil(mapping.mode, "mode for " .. key .. " should be defined")
			end
		end)

		describe("with overrides", function()
			it("overrides an existing key", function()
				local keys = util.build_keymaps({ ["<CR>"] = { "select_next", mode = { "n", "i" } } })
				assert.are.same({ "select_next", mode = { "n", "i" } }, keys.input.keys["<CR>"])
			end)

			it("adds a new key", function()
				local keys = util.build_keymaps({ ["<Esc>"] = { "confirm", mode = { "n", "i" } } })
				assert.is_not_nil(keys.input.keys["<Esc>"])
			end)

			it("does not affect defaults when adding new keys", function()
				local keys = util.build_keymaps({ ["<Esc>"] = { "confirm", mode = { "n", "i" } } })
				assert.is_not_nil(keys.input.keys["<CR>"])
				assert.is_not_nil(keys.input.keys["<Tab>"])
			end)
		end)
	end)
end)
