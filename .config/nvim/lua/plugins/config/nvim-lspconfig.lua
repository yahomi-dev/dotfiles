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

local lsp_group = vim.api.nvim_create_augroup('UserLspConfig', {})
vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
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

require('lspconfig.ui.windows').default_options.border = 'rounded'
