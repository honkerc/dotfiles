return {
    "nvim-treesitter/nvim-treesitter",

    event = "VeryLazy",
    main = "nvim-treesitter.configs",
    opts = {
        ensure_installed = {
            "lua",
            "toml",
            "python",        -- 这里必须加逗号
            "javascript",
            "html",
            "css",
            "json",
            "yaml",
            "markdown",
            "bash",
            "vim",           -- 方便编辑 vim 脚本
        },
        highlight = { enable = true }
    },
    keys = {
        { "<leader>uf", ":NvimTreeToggle<CR>" }
    }
}
