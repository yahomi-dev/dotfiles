local M = {}

local lspconfig = require('lspconfig')
local lsp = require('util.lsp')
local on_attach = require('plugins.config.lsp.on_attach')
local diagnostic_config = require('plugins.config.lsp.diagnostics')
local keymaps = require('plugins.config.lsp.keymaps')

-- Diagnostic settings
vim.diagnostic.config(diagnostic_config)

-- Diagnostic signs
local function setup_signs()
  local signs = { Error = '', Warn = '', Hint = '󰌶', Info = '' }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end
setup_signs()

-- LSP servers setup
local efm_languages = require('plugins.config.lsp.efm').settings.languages
local filetypes = vim.tbl_keys(efm_languages)
M.setup_servers = function()
  -- lspconfig.efm.setup {
  --   on_attach = on_attach.enable_format,
  --   init_options = { documentFormatting = true },
  --   settings = {
  --     languages = efm_languages,
  --   },
  --   filetypes = filetypes,
  -- }

  lspconfig.efm.setup {
    on_attach = function(client, bufnr)
      -- フォーマットをサポートしているか確認
      if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd('BufWritePre', {
          group = vim.api.nvim_create_augroup('LspFormatting', {}),
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format { async = false }
          end,
        })
      end
    end,
    init_options = { documentFormatting = true },
    settings = {
      languages = {
        lua = { { formatCommand = 'stylua -', formatStdin = true } },
      },
    },
    filetypes = { 'lua' },
  }

  lspconfig.biome.setup {
    on_attach = function(client, bufnr)
      if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd('BufWritePre', {
          group = vim.api.nvim_create_augroup('LspFormatting', {}),
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format { async = true }
          end,
        })
      end
    end,
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }

  lspconfig.ts_ls.setup {
    on_attach = function(client, bufnr)
      -- ts_ls のフォーマットを無効化
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    -- root_dir = function(path)
    --   return lsp.find_node_root(vim.fs.dirname(path))
    -- end,
    -- filetypes = lsp.ft.js_like,
  }
end

-- Attach keymaps for LSP
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf
    keymaps.setup_keymaps(bufnr) -- 正しく呼び出す
  end,
})

-- Set diagnostic border style
require('lspconfig.ui.windows').default_options.border = 'rounded'

return M
