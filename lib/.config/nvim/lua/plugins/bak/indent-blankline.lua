return {
	"lukas-reineke/indent-blankline.nvim",
	event = "VeryLazy",
	main = "ibl",
	opts = {
        indent = {
			char = "▏",  -- Unicode U+258F，最细的竖线
			tab_char = "▏",
		},
		exclude = {
			filetypes = {
				"dashboard",
				"NvimTree",
				"TelescopePrompt",
				"alpha",
			},
		},
	},
}
