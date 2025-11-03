return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	event = "VeryLazy",
	config = function()
		require("lualine").setup({
			options = {
				theme = "auto",
				globalstatus = true,
			},
			sections = {
				-- lualine_b = { "branch", "diff" },
				lualine_x = {
					"filesize",
					"encoding",
					"filetype",
				},
			},
			-- winbar = {
			-- 	lualine_a = {},
			-- 	lualine_b = {},
			-- 	lualine_c = {"filename"},
			-- 	lualine_x = {"filetype"},
			-- 	lualine_y = {},
			-- 	lualine_z = {},
			-- },
			extensions = {'nvim-tree', 'fugitive', 'toggleterm'}
		})
	end,
}
