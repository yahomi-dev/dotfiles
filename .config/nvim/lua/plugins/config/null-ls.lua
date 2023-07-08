local null_ls = require('null-ls')
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettier.with({
      filetypes = { 'javascript', 'lua', 'vue', 'typescript' },
    }),
  },
  command = 'prettier',
  debug = false,
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end
      })
    end
  end
})

vim.api.nvim_set_keymap('n', '<leader>fm', '<cmd>lua vim.lsp.buf.format()<CR>',
  { noremap = true }
)

