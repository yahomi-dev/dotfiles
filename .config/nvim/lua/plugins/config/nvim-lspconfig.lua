-- Diagnostic signs
local signs = { Error = '', Warn = '', Hint = '󰌶', Info = '' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- ref: https://neovim.io/doc/user/lsp.html
--    : https://github.com/neovim/nvim-lspconfig/blob/da7461b596d70fa47b50bf3a7acfaef94c47727d/doc/lspconfig.txt#L444-L476
--    : https://zenn.dev/botamotch/articles/21073d78bc68bf
vim.keymap.set('n', ',]', vim.diagnostic.goto_next)
vim.keymap.set('n', ',[', vim.diagnostic.goto_prev)
vim.keymap.set('n', 'gl', vim.diagnostic.setloclist)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf
    local bufopts = { buffer = bufnr, silent = true }

    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'zq', '<Cmd>Telescope diagnostics<CR>', bufopts)
    vim.keymap.set('n', ';d', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', ';i', '<Cmd>Telescope lsp_implementations<CR>', bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', ';t', '<Cmd>Telescope lsp_type_definitions<CR>', bufopts)
    vim.keymap.set('n', ';r', '<Cmd>Telescope lsp_references<CR>', bufopts)
    vim.keymap.set('n', ';a', vim.lsp.buf.code_action, bufopts)
  end,
})

vim.diagnostic.config {
  virtual_text = {
    prefix = '●', -- エラーメッセージの前に表示する文字を変更
    spacing = 2, -- メッセージとライン間のスペース
    format = function(diagnostic)
      local code = diagnostic.code or '' -- コードがある場合は取得
      local source = diagnostic.source or '' -- ソースがある場合は取得
      return string.format('%s (%s: %s)', diagnostic.message, source, code)
    end,
  },
  float = {
    source = 'always', -- 常にエラーメッセージを表示
    border = 'rounded', -- フロートウィンドウの境界を丸くする
  },
}

-- エラーメッセージを表示するキーバインドを設定（例: `K`キーで表示）
vim.keymap.set('n', 'L', vim.diagnostic.open_float, { noremap = true, silent = true })

require('lspconfig.ui.windows').default_options.border = 'rounded'

local lsp = require('util.lsp')
local lspconfig = require('lspconfig')
local lsp_config_table = {}

local stylua = {
  formatCommand = 'stylua -',
  formatStdin = true,
}

-- 保存時に自動フォーマットを実行
local on_attach = function(client, bufnr)
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('LspFormatting', {}),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format { async = false }
      end,
    })
  end
end

-- efm-langserverにstyluaを適用
lspconfig.efm.setup {
  on_attach = on_attach,
  init_options = { documentFormatting = true },
  settings = {
    languages = {
      lua = { stylua },
    },
  },
  filetypes = { 'lua' }, -- `lua`ファイルに適用
}

-- ts_ls
lspconfig.ts_ls.setup {
  on_attach = on_attach,
  single_file_support = false,
  root_dir = function(path)
    return lsp.find_node_root(vim.fs.dirname(path))
  end,
  capabilities = lsp.capabilities,
  filetype = lsp.ft.js_like,
}

local function setup_lsp_global()
  vim.lsp.set_log_level(vim.log.levels.DEBUG)

  -- サーバー毎の設定を反映させる
  for name, config in pairs(lsp_config_table) do
    lspconfig[name].setup(config)
  end
end

local function register_lsp_servers()
  -- サーバー毎の設定を反映させる
  local function register(name, config)
    config.capabilities = capabilities
    lsp_config_table[name] = config
  end

  register('efm', require('plugins.config.lsp.efm'))
end

-- setup_lsp_global()
-- register_lsp_servers()
