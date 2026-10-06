return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",                     -- 关键：使用 main 分支
    event = "VeryLazy",
    main = "nvim-treesitter.config",     -- 关键：模块名从 configs 改为 config
    build = ":TSUpdate",                 -- 确保解析器自动更新
    opts = {
        ensure_installed = {
            "lua",
            "toml",
            "python",
            "javascript",
            "html",
            "css",
            "json",
            "yaml",
            "markdown",
            "bash",
            "vim",
        },
        highlight = { enable = true }
    },
    keys = {
        { "<leader>uf", ":NvimTreeToggle<CR>" }
    }
}
