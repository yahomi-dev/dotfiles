local M = {}

-- キー設定の関数
M.setup_keymaps = function(bufnr)
	local bufopts = { buffer = bufnr, silent = true }

	-- キーのマッピング
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n', 'zq', '<Cmd>Telescope diagnostics<CR>', bufopts)
	vim.keymap.set('n', ';d', vim.lsp.buf.definition, bufopts)
	vim.keymap.set('n', ';i', '<Cmd>Telescope lsp_implementations<CR>', bufopts)
	vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
	vim.keymap.set('n', ';t', '<Cmd>Telescope lsp_type_definitions<CR>', bufopts)
	vim.keymap.set('n', ';r', '<Cmd>Telescope lsp_references<CR>', bufopts)
	vim.keymap.set('n', ';a', vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n', 'L', vim.diagnostic.open_float, { noremap = true, silent = true })
end

return M
