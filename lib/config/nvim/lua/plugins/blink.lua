return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "nvim-tree/nvim-web-devicons",
    "onsails/lspkind.nvim",
    {
      "saghen/blink.pairs",
      version = "*",
      build = function()
        require("blink.pairs").download():pwait(60000)
      end,
      dependencies = { "saghen/blink.download" },
      opts = {},
    },
  },
  event = "InsertEnter",
  opts = {
    completion = {
      menu = {
        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        draw = {
          columns = { { "kind_icon" }, { "label", gap = 1 } },
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                local icon = ctx.kind_icon
                if ctx.source_name and vim.tbl_contains({ "Path" }, ctx.source_name) then
                  local ok, devicons = pcall(require, "nvim-web-devicons")
                  if ok then
                    local dev_icon, _ = devicons.get_icon(ctx.label or "")
                    if dev_icon then
                      icon = dev_icon
                    end
                  end
                else
                  local ok, lspkind = pcall(require, "lspkind")
                  if ok then
                    icon = lspkind.symbolic(ctx.kind or "Text", {
                      mode = "symbol",
                    }) or icon
                  end
                end
                return (icon or "") .. (ctx.icon_gap or "")
              end,
              highlight = function(ctx)
                local hl = "BlinkCmpKind" .. (ctx.kind or "Text")
                if ctx.source_name and vim.tbl_contains({ "Path" }, ctx.source_name) then
                  local ok, devicons = pcall(require, "nvim-web-devicons")
                  if ok then
                    local dev_icon, dev_hl = devicons.get_icon(ctx.label or "")
                    if dev_icon then
                      hl = dev_hl or hl
                    end
                  end
                end
                return hl
              end,
            },
          },
        },
      },
      documentation = {
        auto_show = true,
        window = {
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      },
    },
    keymap = {
      preset = "super-tab",
    },
    snippets = {
      preset = "default", -- 使用 Neovim 原生 vim.snippet 引擎
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
  config = function(_, opts)
    local ok_blink, blink = pcall(require, "blink.cmp")
    if ok_blink then
      blink.setup(opts)
    else
      vim.notify("blink.cmp not found", vim.log.levels.ERROR)
    end
  end,
}
