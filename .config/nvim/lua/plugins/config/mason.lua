require('mason').setup {
  ui = {
    border = 'rounded',
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
}

local on_attach = function(client, bufnr)
  -- LSPが持つフォーマット機能を無効化する
  client.server_capabilities.documentFormattingProvider = false
end

-- nvim-lspを連携
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

local mason_lspconfig = require('mason-lspconfig')

mason_lspconfig.setup {
  ensure_installed = {
    'lua_ls',
    'jsonls',
    'rust_analyzer',
    'cssls',
    'tailwindcss',
    'vtsls',
    'volar',
    'prismals',
  },
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      on_attach = on_attach, -- keyバインドなどの設定を登録
      capabilities = capabilities, -- cmpを連携
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
          format = {
            enable = false, -- Use StyLua
          },
        },
      },
    }
  end,
}
