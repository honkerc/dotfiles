-- 放在 init.lua 最顶部
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- 稳定版
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("basic")
require("keymaps")
require("plugins.lazy")
