return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	event = "VeryLazy",
	config = function()
		local registry = require("mason-registry")

		-- 添加 Python 格式化工具
		local function install(name)
			local success, package = pcall(registry.get_package, name)
			if success and not package:is_installed() then
				package:install()
			end
		end

		install("stylua")
		install("black") -- 添加 Python 格式化工具
		install("prettier") -- 添加 Python 格式化工具

		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,

				-- Python 格式化配置
				null_ls.builtins.formatting.black.with({
					extra_args = { "--fast" }, -- 加速格式化
					filetypes = { "python" }, -- 指定文件类型
				}),
			},
		})
	end,

	keys = {
		{ "<leader>f", vim.lsp.buf.format,desc="code format" }, -- 格式化快捷键
	},
}
-- return {
-- 	"nvimtools/none-ls.nvim",
-- 	dependencies = {
-- 		"nvim-lua/plenary.nvim",
-- 	},
-- 	event = "VeryLazy",
-- 	config = function()
-- 		local registry = require("mason-registry")
--
-- 		local function install(name)
-- 			local success, package = pcall(registry.get_package, name)
-- 			if success and not package:is_installed() then
-- 				package:install()
-- 			end
-- 		end
--
-- 		install("stylua")
-- 		install("autopep8")
--
-- 		local null_ls = require("null-ls")
-- 		null_ls.setup({
-- 			sources = {
-- 				null_ls.builtins.formatting.stylua,
-- 				null_ls.builtins.formatting.autopep8,
-- 			},
-- 		})
-- 	end,
--
-- 	keys = {
-- 		{ "<leader>i", vim.lsp.buf.format },
-- 	},
-- }
