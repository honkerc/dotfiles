return {
	"akinsho/bufferline.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	lazy = false,
	config = function()
		vim.opt.termguicolors = true
		require("bufferline").setup({
			options = {
				mode = "buffers",
				-- 确保这些选项启用
				numbers = "none",
				indicator = {
					icon = "none", -- 使用竖线作为指示器
					style = "none",
				},
				offsets = {
					{
						filetype = "NvimTree",
						text = "",
						-- text = function()
						-- 	-- 获取当前工作目录（NvimTree的根目录）
						-- 	local cwd = vim.fn.getcwd()
						-- 	-- 提取最后一个目录名
						-- 	local last_dir = vim.fn.fnamemodify(cwd, ":t")
						-- 	-- 返回显示文本（可以加上图标）
						-- 	return " " .. last_dir .. "/"
						-- end,
						separator = false,
						text_align = "left",
					},
				},
				-- 禁用可能导致问题的视觉效果
				separator_style = "thin", -- 避免使用"slant"或"thick"
				-- 显示所有缓冲区，即使只有一个
				always_show_bufferline = false,
				show_buffer_close_icons = true,
				auto_toggle_bufferline = true,
				diagnostics = "nvim_lsp",
			},
		})
	end,
	keys = {
		{ "<A-q>", "<Cmd>bdelete<CR>", silent = true, desc = "[Buffer] Close buffer" },
		{ "<A-S-q>", "<Cmd>BufferLineCloseOthers<CR>", silent = true, desc = "[Buffer] Close other buffers" },
		{ "<A-<>", "<CMD>BufferLineCyclePrev<CR>", mode = { "n" }, desc = "[Buffer] Move buffer left" },
		{ "<A->>", "<CMD>BufferLineCycleNext<CR>", mode = { "n" }, desc = "[Buffer] Move buffer right" },
		{ "<A-1>", "<CMD>BufferLineGoToBuffer 1<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 1" },
		{ "<A-2>", "<CMD>BufferLineGoToBuffer 2<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 2" },
		{ "<A-3>", "<CMD>BufferLineGoToBuffer 3<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 3" },
		{ "<A-4>", "<CMD>BufferLineGoToBuffer 4<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 4" },
		{ "<A-5>", "<CMD>BufferLineGoToBuffer 5<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 5" },
		{ "<A-6>", "<CMD>BufferLineGoToBuffer 6<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 6" },
		{ "<A-7>", "<CMD>BufferLineGoToBuffer 7<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 7" },
		{ "<A-8>", "<CMD>BufferLineGoToBuffer 8<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 8" },
		{ "<A-9>", "<CMD>BufferLineGoToBuffer 9<CR>", mode = { "n" }, desc = "[Buffer] Go to buffer 9" },
		{ "<A-h>", "<CMD>BufferLineCyclePrev<CR>", mode = { "n" }, desc = "[Buffer] Previous buffer" },
		{ "<A-l>", "<CMD>BufferLineCycleNext<CR>", mode = { "n" }, desc = "[Buffer] Next buffer" },
	},
}
