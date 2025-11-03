return {
    "nvim-treesitter/nvim-treesitter",

    event = "VeryLazy",
    main = "nvim-treesitter.configs",
    opts = {
        ensure_installed = {
            "lua",
            "toml",
            "python"
        },
        highlight = {enable = true}
    },
    keys = {
        {"<leader>uf",":NvimTreeToggle<CR>"}
    }
}

