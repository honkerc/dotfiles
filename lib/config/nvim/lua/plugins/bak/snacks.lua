return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		dashboard = {
			enabled = true,
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1 ,padding = 1},
                -- { icon = "", title = "", section = "recent_files",padding = 1 },
				-- { icon = "", title = "", section = "projects" },
				{ section = "startup" },
			},
		},
		toggle = {
			enabled = true,
			{
				map = vim.keymap.set, -- keymap.set function to use
				which_key = true, -- integrate with which-key to show enabled/disabled icons and colors
				notify = true, -- show a notification when toggling
				-- icons for enabled/disabled states
				icon = {
					enabled = " ",
					disabled = " ",
				},
				-- colors for enabled/disabled states
				color = {
					enabled = "green",
					disabled = "yellow",
				},
				wk_desc = {
					enabled = "Disable ",
					disabled = "Enable ",
				},
			},
		},
		bigfile = { enabled = true },
		explorer = { enabled = false },
		indent = { enabled = false },
		input = { enabled = false },
		picker = { enabled = false },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
}
