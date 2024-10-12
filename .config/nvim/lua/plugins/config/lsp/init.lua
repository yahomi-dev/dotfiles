local M = {}

local lspconfig = require('lspconfig')
local lsp = require('util.lsp')
local on_attach = require('plugins.config.lsp.on_attach')
local diagnostic_config = require('plugins.config.lsp.diagnostics')

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
    init_options = { documentFormatting = true },
    settings = {
      languages = {
        lua = { { formatCommand = 'stylua -', formatStdin = true } },
      },
    },
    filetypes = { 'lua' },
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }

  lspconfig.biome.setup {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }

  lspconfig.ts_ls.setup {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    -- root_dir = function(path)
    --   return lsp.find_node_root(vim.fs.dirname(path))
    -- end,
    -- filetypes = lsp.ft.js_like,
  }
end

-- Attach keymaps for LSP
local keymaps = require('plugins.config.lsp.keymaps')
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf

    -- setting key map
    keymaps.setup_keymaps(bufnr)

    -- format on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('LspFormatting', {}),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format {
          async = false,
          timeout_ms = 3000,
          filter = function(client)
            return client.name ~= 'ts_ls'
          end,
        }
      end,
    })
  end,
})

-- Set diagnostic border style
require('lspconfig.ui.windows').default_options.border = 'rounded'

return M
