local Picker = require("xdg-nvfilechooser.picker")

describe("Picker", function()
	it("creates a picker instance", function()
		local picker = Picker.new("snacks")
		assert.is_not_nil(picker)
		assert.is_not_nil(picker.impl)
	end)

	it("defaults to snacks backend", function()
		local picker = Picker.new()
		assert.is_not_nil(picker)
		assert.is_not_nil(picker.impl)
	end)

	it("exposes all four interface methods", function()
		local picker = Picker.new("snacks")
		assert.is_function(picker.open_files)
		assert.is_function(picker.open_directories)
		assert.is_function(picker.save_file)
		assert.is_function(picker.save_files)
	end)

	it("falls back to snacks for unknown backend", function()
		local picker = Picker.new("nonexistent_backend")
		assert.is_not_nil(picker)
		assert.is_not_nil(picker.impl)
	end)

	it("delegates open_files to the backend", function()
		local calls = {}
		local mock_backend = {
			open_files = function(opts)
				calls[#calls + 1] = { "open_files", opts }
			end,
			open_directories = function(opts)
				calls[#calls + 1] = { "open_directories", opts }
			end,
			save_file = function(opts)
				calls[#calls + 1] = { "save_file", opts }
			end,
			save_files = function(opts)
				calls[#calls + 1] = { "save_files", opts }
			end,
		}
		local picker = setmetatable({ impl = mock_backend }, getmetatable(Picker.new("snacks")))

		picker:open_files({ key = "val" })
		assert.are.same({ { "open_files", { key = "val" } } }, calls)
	end)

	it("passes keymaps to the backend", function()
		local received = nil
		local mock_backend = {
			open_files = function(opts, keymaps)
				received = keymaps
			end,
			open_directories = function() end,
			save_file = function() end,
			save_files = function() end,
		}
		local picker = setmetatable(
			{ impl = mock_backend, keymaps = { ["<Esc>"] = "close" } },
			getmetatable(Picker.new("snacks"))
		)

		picker:open_files({})
		assert.are.same({ ["<Esc>"] = "close" }, received)
	end)

	it("delegates all four methods correctly", function()
		local calls = {}
		local mock_backend = {
			open_files = function(opts)
				calls[#calls + 1] = "open_files"
			end,
			open_directories = function(opts)
				calls[#calls + 1] = "open_directories"
			end,
			save_file = function(opts)
				calls[#calls + 1] = "save_file"
			end,
			save_files = function(opts)
				calls[#calls + 1] = "save_files"
			end,
		}
		local picker = setmetatable({ impl = mock_backend }, getmetatable(Picker.new("snacks")))

		picker:open_files({})
		picker:open_directories({})
		picker:save_file({})
		picker:save_files({})

		assert.are.same({ "open_files", "open_directories", "save_file", "save_files" }, calls)
	end)
end)
