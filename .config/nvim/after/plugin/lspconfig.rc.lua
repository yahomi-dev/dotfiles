local on_attach = function(client, bufnr)

  -- LSPが持つフォーマット機能を無効化する
  -- →例えばtsserverはデフォルトでフォーマット機能を提供しますが、利用したくない場合はコメントアウトを解除してください
  client.server_capabilities.documentFormattingProvider = false

  -- 下記ではデフォルトのキーバインドを設定しています
  -- ほかのLSPプラグインを使う場合（例：Lspsaga）は必要ないこともあります

  -- local opts = { noremap = true, silent = true }
  -- 
  -- local set = vim.keymap.set
  -- set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  -- set("n", "mk", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  -- set("n", "zq", "<cmd>lua vim.lsp.diagnostic.setloclist()<CR>", opts)
  -- set("n", "<C-m>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  -- set("n", "gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
  -- set("n", "rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  -- set("n", "ma", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  -- set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  -- set("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
  -- set("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)


end

-- nvim-lspを連携
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- この一連の記述で、mason.nvimでインストールしたLanguage Serverが自動的に個別にセットアップされ、利用可能になります
require("mason").setup()
require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers {
  function (server_name) -- default handler (optional)
    require("lspconfig")[server_name].setup {
      on_attach = on_attach, --keyバインドなどの設定を登録
      capabilities = capabilities, --cmpを連携
    }
  end,
}

-- Diagnostic symbols in the sign column

local signs = { Error = " ", Warn = ">>", Hint = ">", Info = ">" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Diagnostic Settings
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  severity_sort = true,
})

vim.diagnostic.config({
  virtual_text = false,
  update_in_insert = false,
  float = {
    source = "always", -- Or "if_many"
  },
})
