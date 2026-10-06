return {
  "xiyaowong/transparent.nvim",
  opts = {
    groups = {
      "Normal",
      "NormalNC",
      "Comment",
      "Constant",
      "Special",
      "Identifier",
      "Statement",
      "PreProc",
      "Type",
      "Underlined",
      "Todo",
      "String",
      "Function",
      "Conditional",
      "Repeat",
      "Operator",
      "Structure",
      "LineNr",
      "NonText",
      "SignColumn",
      "CursorLine",
      "CursorLineNr",
      "StatusLine",
      "StatusLineNC",
      "EndOfBuffer",
    },
    extra_groups = {
      "NormalFloat",
      "NvimTreeNormal",
      "BufferLine",
      -- ===== blink.cmp 菜单相关 =====
      "BlinkCmpMenu",
      "BlinkCmpMenuBorder",
      "BlinkCmpMenuSelection",
      -- 滑块保留不透明
      -- "BlinkCmpScrollBarThumb",
      -- "BlinkCmpScrollBarGutter",
      -- ===== 文档窗口 =====
      "BlinkCmpDoc",
      "BlinkCmpDocBorder",
      "BlinkCmpDocSeparator",
      "BlinkCmpDocCursorLine",
      -- ===== 签名帮助 =====
      "BlinkCmpSignatureHelp",
      "BlinkCmpSignatureHelpBorder",
      -- ===== 标签文字 =====
      "BlinkCmpLabel",
      "BlinkCmpLabelDeprecated",
      "BlinkCmpLabelMatch",
      -- ===== 图标种类 =====
      "BlinkCmpKind",
      "BlinkCmpKindText",
      "BlinkCmpKindMethod",
      "BlinkCmpKindFunction",
      "BlinkCmpKindConstructor",
      "BlinkCmpKindField",
      "BlinkCmpKindVariable",
      "BlinkCmpKindClass",
      "BlinkCmpKindInterface",
      "BlinkCmpKindModule",
      "BlinkCmpKindProperty",
      "BlinkCmpKindUnit",
      "BlinkCmpKindValue",
      "BlinkCmpKindEnum",
      "BlinkCmpKindKeyword",
      "BlinkCmpKindSnippet",
      "BlinkCmpKindColor",
      "BlinkCmpKindFile",
      "BlinkCmpKindReference",
      "BlinkCmpKindFolder",
      "BlinkCmpKindEnumMember",
      "BlinkCmpKindConstant",
      "BlinkCmpKindStruct",
      "BlinkCmpKindEvent",
      "BlinkCmpKindOperator",
      "BlinkCmpKindTypeParameter",
      -- ===== 来源标签 =====
      "BlinkCmpSource",
      "BlinkCmpGhostText",
    },
    exclude_groups = {},
    on_clear = function()
      -- 额外清除边框的前景色，让外围框彻底透明
      local border_groups = {
        "BlinkCmpMenuBorder",
        "BlinkCmpDocBorder",
        "BlinkCmpSignatureHelpBorder",
      }
      for _, group in ipairs(border_groups) do
        vim.api.nvim_set_hl(0, group, { fg = "none", bg = "none" })
      end
    end,
  },
}
