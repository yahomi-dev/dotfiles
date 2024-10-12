local M = {}

-- 通常のon_attach
M.enable_format = function(client, bufnr)
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = vim.api.nvim_create_augroup('LspFormatting', {}),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format { async = false, timeout = 5000 }
      end,
    })
  end
end

-- フォーマットを無効にするon_attach
M.disable_format = function(client, bufnr)
  -- tsserverやフォーマットを無効にしたいサーバー用の処理
  if client.supports_method('textDocument/formatting') then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end
end

return M
