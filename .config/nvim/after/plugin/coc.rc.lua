vim.g.coc_global_extensions = {
  'coc-tsserver',
  'coc-css',
  'coc-vetur',
  'coc-eslint',
  'coc-prettier',
  'coc-fzf-preview',
  'coc-lists'
}

-- Some servers have issues with backup files, see #649
vim.opt.writebackup = false

-- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
-- delays and poor user experience
vim.opt.updatetime = 300

local keyset = vim.keymap.set

-- Autocomplete
function _G.check_back_space()
  local col = vim.fn.col('.') - 1
  return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }

-- 補完の選択
keyset("i", "<C-n>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
keyset("i", "<C-p>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)

keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

-- Use K to show documentation in preview window
function _G.show_docs()
  local cw = vim.fn.expand('<cword>')
  if vim.fn.index({ 'vim', 'help' }, vim.bo.filetype) >= 0 then
    vim.api.nvim_command('h ' .. cw)
  elseif vim.api.nvim_eval('coc#rpc#ready()') then
    vim.fn.CocActionAsync('doHover')
  else
    vim.api.nvim_command('!' .. vim.o.keywordprg .. ' ' .. cw)
  end
end

keyset("n", "K", '<CMD>lua _G.show_docs()<CR>', { silent = true })


vim.api.nvim_create_augroup("CocGroup", {})

-- Setup formatexpr specified filetype(s)
vim.api.nvim_create_autocmd("FileType", {
  group = "CocGroup",
  pattern = "typescript,json",
  command = "setl formatexpr=CocAction('formatSelected')",
  desc = "Setup formatexpr specified filetype(s)."
})

-- Update signature help on jump placeholder
vim.api.nvim_create_autocmd("User", {
  group = "CocGroup",
  pattern = "CocJumpPlaceholder",
  command = "call CocActionAsync('showSignatureHelp')",
  desc = "Update signature help on jump placeholder"
})

-- Apply codeAction to the selected region
-- Example: `<leader>aap` for current paragraph

local opts = { silent = true, nowait = true }

-- Symbol renaming
keyset("n", "rn", "<Plug>(coc-rename)", { silent = true })
keyset("n", "<leader>ma", "<Plug>(coc-codeaction-selected)j", opts)

-- Use `[g` and `]g` to navigate diagnostics
-- Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
keyset("n", "[g", "<Plug>(coc-diagnostic-prev)", { silent = true })
keyset("n", "]g", "<Plug>(coc-diagnostic-next)", { silent = true })


-- Remap <C-f> and <C-b> to scroll float windows/popups
---@diagnostic disable-next-line: redefined-local
local opts = { silent = true, nowait = true, expr = true }
keyset("i", "<C-d>", 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(1)<cr>" : ""', opts)
keyset("i", "<C-u>", 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(0)<cr>" : ""', opts)

-- " Add `:Fold` command to fold current buffer
vim.api.nvim_create_user_command("Fold", "call CocAction('fold', <f-args>)", { nargs = '?' })

-- Add `:OR` command for organize imports of the current buffer
vim.api.nvim_create_user_command("OR", "call CocActionAsync('runCommand', 'editor.action.organizeImport')", {})

-- Add (Neo)Vim's native statusline support
-- NOTE: Please see `:h coc-status` for integrations with external plugins that
-- provide custom statusline: lightline.vim, vim-airline
vim.opt.statusline:prepend("%{coc#status()}%{get(b:,'coc_current_function','')}")

-- Coc.nvimの組み込みFormatter
-- Language Serverを用いたFormat
vim.api.nvim_create_user_command("Format", "call CocAction('format')", {}) --コマンドを登録
keyset("n", "<leader>fm", ":Format<cr>", { silent = true })

-- prettier(coc-prettier)
-- MEMO:coc-prettierでグローバルのprettierを使おうとすると、毎回ポップアップがでてしまう
-- 2023/02/02現在はvim-prettierを使用(vim-prettier.rc.luaを参照)

-- keyset("n","<leader>mm",":<C-u>CocCommand prettier.forceFormatDocument<cr>")
