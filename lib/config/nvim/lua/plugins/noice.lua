return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    -- 先定义高亮组
    vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#1e1e2e" })
    -- 再初始化 notify
    require("notify").setup({
      background_colour = "#1e1e2e",
      -- background_colour = "NotifyBackground",
    })
    -- 最后配置 noice
    require("noice").setup({
      -- 你的 noice 配置
    })
  end,
}
