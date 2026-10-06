return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "L3MON4D3/LuaSnip",
    "nvim-tree/nvim-web-devicons",
    "onsails/lspkind.nvim",
    -- 新增 blink.pairs，使用 download 方式获取预编译二进制
    {
      "saghen/blink.pairs",
      version = "*",
      build = function()
        require("blink.pairs").download():pwait(60000)
      end,
      dependencies = { "saghen/blink.download" },
      opts = {
        -- blink.pairs 的配置选项，可按需调整
        -- 例如：禁用某些文件类型，或自定义高亮颜色
        -- 这里保留为空表，使用默认行为
      },
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
    sources = {
      default = { "path", "snippets", "buffer", "lsp" },
    },
  },
  config = function(_, opts)
    -- 先设置 LuaSnip
    local ok_luasnip, luasnip = pcall(require, "luasnip")
    if ok_luasnip then
      require("luasnip.loaders.from_vscode").lazy_load()

      vim.keymap.set({"i", "s"}, "<C-l>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { silent = true })

      vim.keymap.set({"i", "s"}, "<C-h>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        end
      end, { silent = true })
    end

    -- 最后设置 blink.cmp
    local ok_blink, blink = pcall(require, "blink.cmp")
    if ok_blink then
      blink.setup(opts)
    else
      vim.notify("blink.cmp not found", vim.log.levels.ERROR)
    end
  end,
}
