return {
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    main = "ibl",
    opts = {
        indent = {
            char = "▏",
            highlight = {
                "RainbowDimRed",
                "RainbowDimYellow",
                "RainbowDimBlue",
                "RainbowDimOrange",
                "RainbowDimGreen",
                "RainbowDimViolet",
                "RainbowDimCyan",
            },
        },
        scope = {
            enabled = true,
            char = "▎",
            show_start = false,
            show_end = false,
            highlight = { "RainbowScopeRed" },
        },
        -- 关键：指定一个自定义高亮组，而不是空表
        whitespace = {
            highlight = { "MyIblWhitespace" },
            remove_blankline_trail = true,
        },
        exclude = {
            filetypes = {
                "dashboard", "NvimTree", "TelescopePrompt", "alpha",
                "help", "packer", "neogitstatus", "Trouble",
            },
        },
    },
    config = function(_, opts)
        local hooks = require("ibl.hooks")
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            -- 柔和低饱和缩进色（只有 fg，无 bg）
            vim.api.nvim_set_hl(0, "RainbowDimRed",    { fg = "#b06a6a" })
            vim.api.nvim_set_hl(0, "RainbowDimYellow", { fg = "#b0b06a" })
            vim.api.nvim_set_hl(0, "RainbowDimBlue",   { fg = "#6a7ab0" })
            vim.api.nvim_set_hl(0, "RainbowDimOrange", { fg = "#b08a6a" })
            vim.api.nvim_set_hl(0, "RainbowDimGreen",  { fg = "#6ab06a" })
            vim.api.nvim_set_hl(0, "RainbowDimViolet", { fg = "#8a6ab0" })
            vim.api.nvim_set_hl(0, "RainbowDimCyan",   { fg = "#6ab0b0" })

            -- 当前作用域：醒目的红色
            vim.api.nvim_set_hl(0, "RainbowScopeRed", { fg = "#ff5555" })

            -- 自定义 whitespace 高亮组：只有前景色，没有背景色
            vim.api.nvim_set_hl(0, "MyIblWhitespace", { fg = "#4a4a4a" })
        end)
        require("ibl").setup(opts)
    end,
}
