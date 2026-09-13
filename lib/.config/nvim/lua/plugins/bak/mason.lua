return {
  "williamboman/mason.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    "williamboman/mason-lspconfig.nvim",
  },
  opts = {},
  config = function(_, opts)
    require("mason").setup(opts)
    local registry = require("mason-registry")

    -- 定义Mason包名与新LSP配置名的映射关系
    local package_to_lsp = {
      ["lua-language-server"] = "lua_ls",
      ["vue-language-server"] = "vuels",
      ["pyright"] = "pyright",
      ["html-lsp"] = "html",
      ["css-lsp"] = "cssls",
      ["emmet-ls"] = "emmet_ls",
      ["marksman"] = "marksman"  -- 添加 Markdown LSP
    }

    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local on_attach = function(client, bufnr)
      -- 禁用格式化功能，可以留给如Null-ls或EFM之类的专用插件
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      -- 您可以在这里添加其他的按键映射或LSP附加设置
    end

    local function setup(mason_package_name, config)
      -- 确保Mason包已安装
      local success, package = pcall(registry.get_package, mason_package_name)
      if success and not package:is_installed() then
        package:install()
      end

      -- 获取正确的LSP服务器名称
      local lsp_server_name = package_to_lsp[mason_package_name]

      -- 合并基础配置
      local final_config = vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = on_attach,
      }, config or {})

      -- 使用新的 vim.lsp.config API 启动服务器
      if lsp_server_name then
        vim.lsp.config(lsp_server_name, final_config)
        -- 显式启用服务器
        vim.lsp.enable(lsp_server_name)
      else
        vim.notify("LSP配置 '" .. mason_package_name .. "' 未找到映射关系。", vim.log.levels.WARN)
      end
    end

    -- 配置特定的语言服务器
    setup("lua-language-server", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          telemetry = { enable = false },
        },
      },
    })

    setup("vue-language-server", {}) -- 可根据需要添加Vue特定配置

    setup("pyright", {
      settings = {
        python = {
          pythonPath = "/home/clay/.venv/bin/python3",
          analysis = {
            typeCheckingMode = "basic",
          },
        },
      },
    })

    setup("html-lsp", {})
    setup("css-lsp", {})
    setup("emmet-ls", {})

    -- 添加 Markdown LSP 配置
    setup("marksman", {})

    -- 全局诊断配置
    vim.diagnostic.config({
      virtual_text = true,
    })
  end,
}
