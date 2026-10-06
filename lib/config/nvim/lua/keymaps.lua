-- vim.keymap.set(mode,lhs,rhs,opts)
-- mode n/i/c table()
-- lhs hot key
-- rhs funtion
-- opts:table other options for keymap

-- set leader
vim.g.mapleader = "\\"
vim.g.localleader = "\\"

-- undo
vim.keymap.set({"n","i"}, "<leader>z", "<Cmd>undo<CR>", {silent = true})

-- 插入模式下 jk 映射为 Esc
vim.keymap.set({"n","i"}, "jk", "<Esc>", { noremap = true, silent = true })

-- save
vim.keymap.set({"n","i"}, "ww", "<Cmd>w!<CR>", {silent = true})
vim.keymap.set({"n","i"}, "wq", "<Cmd>wq!<CR>", {silent = true})

-- quit
vim.keymap.set({"n","i"}, "qq", "<Cmd>q!<CR>", {silent = true})

-- 复制（Copy）
vim.keymap.set({'n', 'v'}, '<leader>c', '"+y', { noremap = true, silent = true })

-- 粘贴（Paste）
vim.keymap.set({'n', 'i'}, '<leader>v', '"+p', { noremap = true, silent = true })

-- 剪切（Cut）
vim.keymap.set({'n', 'v'}, '<leader>x', '"+d', { noremap = true, silent = true })

-- 全选（Select all）
vim.keymap.set('n', '<leader>a', 'ggVG', { noremap = true, silent = true })
