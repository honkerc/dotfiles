return {

	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	-- 延迟加载
	event = "VeryLazy",
	opts = {
		actions = {
			open_file = {
				quit_on_open = false
			},
		},
		renderer = {
			-- root_folder_label = ":~:s?.*??",  -- 完全隐藏路径
			root_folder_label = function(path)
				-- 提取路径中的最后一个目录
				local last_dir = vim.fn.fnamemodify(path, ":t")
				-- 添加文件夹图标和斜杠
				return "  " .. last_dir .. "/"
			end,
			indent_markers = {
				enable = true,
				inline_arrows = true,
				icons = {
					corner = "└",
					edge = "│",
					item = "│",
					bottom = "─",
					none = " ",
				},
			},
		},
		view = {
			-- 隐藏窗口顶部的标题栏
			-- hide_root_folder = true,
			width = 25,
			side = "left",
			-- 添加这些配置来完全隐藏标题栏
			signcolumn = "no",
			number = false,
			relativenumber = false,
		},
		-- 禁用一些可能影响性能的功能
	},
	keys = {
		{ "<leader>e", "<Cmd>NvimTreeToggle<CR>", nowait = true },
	},
}
