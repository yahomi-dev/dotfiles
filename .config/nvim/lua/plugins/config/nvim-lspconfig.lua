local lspconfig = require('lspconfig')

-- ref: https://github.com/neovim/neovim/commit/a5bbb932f9094098bd656d3f6be3c58344576709
vim.fn.sign_define(
  'DiagnosticSignError',
  { text = '', texthl = 'DiagnosticSignError', numhl = 'DiagnosticSignError' }
)
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn', numhl = 'DiagnosticSignWarn' })
-- vim.fn.sign_define('DiagnosticSignHint', { text = '󰌶', texthl = 'DiagnosticSignHint', numhl = 'DiagnosticSignHint' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint', numhl = 'DiagnosticSignHint' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo', numhl = 'DiagnosticSignInfo' })

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
    local bufopts = { buffer = bufnr }

    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'zq', '<Cmd>Telescope diagnostics<CR>')
    vim.keymap.set('n', ';d', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', ';i', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set({ 'n' }, ';i', '<Cmd>Telescope lsp_implementations<CR>')
    vim.keymap.set({ 'n' }, ';t', '<Cmd>Telescope lsp_type_definitions<CR>')
    vim.keymap.set({ 'n' }, ';r', '<Cmd>Telescope lsp_references<CR>')
    vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', ';a', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', ';r', vim.lsp.buf.references, bufopts)

    -- ref: https://vi.stackexchange.com/questions/39074/user-borders-around-lsp-floating-windows
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = 'rounded',
    })
    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = 'rounded',
    })
    vim.diagnostic.config {
      float = { border = 'rounded' },
    }
  end,
})

require('lspconfig.ui.windows').default_options.border = 'rounded'
