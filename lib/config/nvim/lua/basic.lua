-- 基础配置
-- 行号
vim.opt.number = true

-- 相对行号
vim.opt.relativenumber = true

-- higelight line
vim.opt.cursorline = true

-- notice line max word
vim.opt.colorcolumn = ""

-- tab length
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- auto read config
vim.opt.autoread = true

-- split window
vim.opt.splitbelow = true
vim.opt.splitright = true

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- show mode
vim.opt.showmode = false

-- swapfile
vim.opt.swapfile = false

-- clipboard
vim.opt.clipboard = "unnamedplus"

--  侧边的错误提示
vim.diagnostic.config({
  signs = false,      -- 隐藏侧边图标
  virtual_text = true -- 保留行内错误文本（可选关闭）
})

-- 禁用 netrw（必须放在 nvim-tree 加载之前）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- 启用真彩色（使主题和图标显示更美观）
vim.opt.termguicolors = true
vim.g.python3_host_prog = '/home/clay/.venv/bin/python3'
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
