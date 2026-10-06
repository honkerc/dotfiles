return {
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("cyberdream").setup({
				-- Cyberdream 的配置选项
				transparent = false,
				italic_comments = true,
				hide_fillchars = true,
				borderless_telescope = true,
				terminal_colors = true,
			})
			-- 如果你想让 cyberdream 作为默认主题，取消下面注释：
			-- vim.cmd("colorscheme cyberdream")
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "moon",
			-- transparent = true,
			terminal_colors = true,
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
			},
		},
		-- config = function(_, opts)
		-- 	require("tokyonight").setup(opts)
		-- 	vim.cmd("colorscheme tokyonight")
		-- end,
	},
	{
		"maxmx03/dracula.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			---@type dracula
			local dracula = require("dracula")

			dracula.setup({
				styles = {
					Type = {},
					Function = {},
					Parameter = {},
					Property = {},
					Comment = {},
					String = {},
					Keyword = {},
					Identifier = {},
					Constant = {},
				},
				transparent = false,
				on_colors = function(colors, color)
					---@type dracula.palette
					return {
						-- override or create new colors
						mycolor = "#ffffff",
						-- mycolor = 0xffffff,
					}
				end,
				on_highlights = function(colors, color)
					---@type dracula.highlights
					return {
						---@type vim.api.keyset.highlight
						Normal = { fg = colors.mycolor },
					}
				end,
				plugins = {
					["nvim-treesitter"] = true,
					["rainbow-delimiters"] = true,
					["nvim-lspconfig"] = true,
					["nvim-navic"] = true,
					["nvim-cmp"] = true,
					["indent-blankline.nvim"] = true,
					["neo-tree.nvim"] = true,
					["nvim-tree.lua"] = true,
					["which-key.nvim"] = true,
					["dashboard-nvim"] = true,
					["gitsigns.nvim"] = true,
					["neogit"] = true,
					["todo-comments.nvim"] = true,
					["lazy.nvim"] = true,
					["telescope.nvim"] = true,
					["noice.nvim"] = true,
					["hop.nvim"] = true,
					["mini.statusline"] = true,
					["mini.tabline"] = true,
					["mini.starter"] = true,
					["mini.cursorword"] = true,
					["bufferline.nvim"] = true,
				},
			})
			vim.cmd.colorscheme("dracula")
			-- vim.cmd.colorscheme("dracula-soft")
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "auto", -- latte, frappe, macchiato, mocha
				background = { -- :h background
					light = "latte",
					dark = "mocha",
				},
				transparent_background = false, -- disables setting the background color.
				float = {
					transparent = false, -- enable transparent floating windows
					solid = false, -- use solid styling for floating windows, see |winborder|
				},
				show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
				term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
				dim_inactive = {
					enabled = false, -- dims the background color of inactive window
					shade = "dark",
					percentage = 0.15, -- percentage of the shade to apply to the inactive window
				},
				no_italic = false, -- Force no italic
				no_bold = false, -- Force no bold
				no_underline = false, -- Force no underline
				styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
					comments = { "italic" }, -- Change the style of comments
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
					-- miscs = {}, -- Uncomment to turn off hard-coded styles
				},
				lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
					virtual_text = {
						errors = { "italic" },
						hints = { "italic" },
						warnings = { "italic" },
						information = { "italic" },
						ok = { "italic" },
					},
					underlines = {
						errors = { "underline" },
						hints = { "underline" },
						warnings = { "underline" },
						information = { "underline" },
						ok = { "underline" },
					},
					inlay_hints = {
						background = true,
					},
				},
				color_overrides = {},
				custom_highlights = {},
				default_integrations = true,
				auto_integrations = false,
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					notify = false,
					mini = {
						enabled = true,
						indentscope_color = "",
					},
					-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
				},
			})

			-- setup must be called before loading
			-- vim.cmd.colorscheme("catppuccin")
		end,
	},
}
