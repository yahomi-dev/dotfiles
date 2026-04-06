local map = vim.keymap.set
local nmap = function(lhs, rhs, opts)
  map('n', lhs, rhs, opts)
end

-- <Space> を何もしないキーに（leader との競合防止）
map('n', '<Space>', '<Nop>', { noremap = true })

-- ターミナルモードで Esc でノーマルモードに
map('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

-- 論理行と物理行の移動を入れ替え
map('n', 'j', 'gj', { noremap = true })
map('n', 'k', 'gk', { noremap = true })
map('v', 'j', 'gj', { noremap = true })
map('v', 'k', 'gk', { noremap = true })
map('n', '<Down>', 'gj', { noremap = true })
map('n', '<Up>', 'gk', { noremap = true })
map('n', 'gj', 'j', { noremap = true })
map('n', 'gk', 'k', { noremap = true })

-- インサートモード中の移動を Emacs 風に
map('i', '<C-f>', '<Right>', { noremap = true })
map('i', '<C-b>', '<Left>', { noremap = true })
map('i', '<C-p>', '<Up>', { noremap = true })
map('i', '<C-n>', '<Down>', { noremap = true })

-- ウィンドウ移動
nmap('<C-h>', '<C-w>h')
nmap('<C-j>', '<C-w>j')
nmap('<C-l>', '<C-w>l')

-- バッファ移動
nmap('<S-l>', ':bnext<CR>')
nmap('<S-h>', ':bprevious<CR>')

-- インデント維持
map('v', '<', '<gv')
map('v', '>', '>gv')

-- 検索ハイライト解除
map('n', '<Esc><Esc>', ':nohl<CR>', { noremap = true, silent = true })

-- 検索時に画面中央に
nmap('n', 'nzz')
nmap('N', 'Nzz')
nmap('*', '*zz')
nmap('#', '#zz')

-- Split window
map('n', 'vs', ':vsplit<CR><C-w>w', { noremap = true })

-- New tab
map('n', 'te', ':tabedit', { noremap = true })
map('n', 'gb', 'gT', { noremap = true })

-- va" を vi2" に
for _, quote in ipairs { '"', "'", '`' } do
  map({ 'x', 'o' }, 'a' .. quote, '2i' .. quote)
end

-- ファイルパスをクリップボードにコピー
nmap('<leader>Y', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path, vim.log.levels.INFO)
end, { desc = 'Copy full file path to clipboard' })

nmap('<leader>y', function()
  local full_path = vim.fn.expand('%:p')
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  local final_path = full_path
  if git_root and vim.v.shell_error == 0 then
    local git_root_normalized = git_root:gsub('/$', '')
    if full_path:find(git_root_normalized, 1, true) == 1 then
      final_path = full_path:sub(#git_root_normalized + 2)
    end
  end
  vim.fn.setreg('+', final_path)
  vim.notify('Copied: ' .. final_path, vim.log.levels.INFO)
end, { desc = 'Copy Git-relative or full file path to clipboard' })

-- LSP キーマップ（LspAttach 時に設定）
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    map('n', 'K', vim.lsp.buf.hover, opts)
    map('n', 'L', vim.diagnostic.open_float, opts)
    map('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    map('n', ';d', vim.lsp.buf.definition, opts)
    map('n', ';i', '<Cmd>Telescope lsp_implementations<CR>', opts)
    map('n', ';t', '<Cmd>Telescope lsp_type_definitions<CR>', opts)
    map('n', ';r', '<Cmd>Telescope lsp_references<CR>', opts)
    map('n', ';a', vim.lsp.buf.code_action, opts)
    map('n', '<leader>rn', vim.lsp.buf.rename, opts)
    map('n', 'zq', '<Cmd>Telescope diagnostics<CR>', opts)
  end,
})
