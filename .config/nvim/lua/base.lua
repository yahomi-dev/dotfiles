vim.cmd('autocmd!')

-- encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.scriptencoding = 'utf-8'

-- tab
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- visual
vim.opt.list = false
vim.opt.number = true -- 行番号表示
vim.opt.laststatus = 3 -- vs時ステータスラインが分割しないように
vim.opt.display = 'lastline' -- 長い行が@で省略されないように
vim.opt.showmode = false -- モード表示をOFF(luaLineにて表示)
vim.opt.showmatch = true -- 括弧の対応をハイライト
vim.opt.matchtime = 1 -- 括弧の対を見つけるミリ秒数
vim.opt.showcmd = true -- 入力中のコマンドを表示
vim.opt.cursorline = true -- カレント行を強調
vim.opt.wrap = true -- 画面幅で折り返す
vim.opt.title = false -- タイトルを書き換えないように
vim.opt.scrolloff = 5 -- スクロール時の上下padding付与
vim.opt.sidescrolloff = 5 -- (opt.wrap=trueなので横はスクロールしない)
vim.opt.pumheight = 10 -- 補完候補の表示数
vim.opt.pumblend = 10 -- 補完候補窓の透明度
vim.opt.termguicolors = true
vim.opt.mouse = {} -- マウス操作を無効化

-- search
vim.opt.wrapscan = false -- ファイル末尾まで検索後、上に戻らないように
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.api.nvim_set_keymap('n', '<Esc><Esc>', ':nohl<CR>', { noremap = true, silent = true})


vim.g.mapleader = ' '
vim.opt.clipboard = 'unnamedplus'
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 50

vim.opt.confirm = true
vim.opt.undofile = true -- アンドゥファイルを作る
vim.cmd([[
set undodir=~/.vim/undodir
]])
vim.opt.backup = false   -- バックアップ取らない
vim.opt.swapfile = false -- スワップファイル作らない
vim.opt.hidden = false -- 編集中の場合、他のファイルを開けないように
vim.opt.autoread = true -- 他で書き換えられたら自動で読み直す
vim.opt.winblend = 5

vim.cmd('au TextYankPost * silent! lua vim.highlight.on_yank {higroup = "visual", timeout=500}')

vim.cmd([[
  let @b = "/{\\<CR>jV/\\n\\n\\<CR>:sort i\\<CR>"
  command! SortCSS normal @b
]])



vim.api.nvim_set_keymap('n', '<Esc><Esc>', ':nohl<CR>', { noremap = true, silent = true})

vim.cmd([[
  command! SortCSSProperties :call SortCSSProperties()
]])


---------------------------------------------------------------------------------------------------+
-- Commands \ Modes | Normal | Insert | Command | Visual | Select | Operator | Terminal | Lang-Arg |
-- ================================================================================================+
-- map  / noremap   |    @   |   -    |    -    |   @    |   @    |    @     |    -     |    -     |
-- nmap / nnoremap  |    @   |   -    |    -    |   -    |   -    |    -     |    -     |    -     |
-- map! / noremap!  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    -     |
-- imap / inoremap  |    -   |   @    |    -    |   -    |   -    |    -     |    -     |    -     |
-- cmap / cnoremap  |    -   |   -    |    @    |   -    |   -    |    -     |    -     |    -     |
-- vmap / vnoremap  |    -   |   -    |    -    |   @    |   @    |    -     |    -     |    -     |
-- xmap / xnoremap  |    -   |   -    |    -    |   @    |   -    |    -     |    -     |    -     |
-- smap / snoremap  |    -   |   -    |    -    |   -    |   @    |    -     |    -     |    -     |
-- omap / onoremap  |    -   |   -    |    -    |   -    |   -    |    @     |    -     |    -     |
-- tmap / tnoremap  |    -   |   -    |    -    |   -    |   -    |    -     |    @     |    -     |
-- lmap / lnoremap  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    @     |
---------------------------------------------------------------------------------------------------+

-- ターミナルモードでインサートモードからEscでノーマルモードに
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', '<Down>', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', '<Up>', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', 'gj', 'j', { noremap = true })
vim.api.nvim_set_keymap('n', 'gk', 'k', { noremap = true })

vim.api.nvim_set_keymap('n', '<Space>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Plug>(lsp)', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', 'm', '<Plug>(lsp)', { noremap = true })
vim.api.nvim_set_keymap('n', '<Plug>(ff)', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('n', 'z', '<Plug>(ff)', { noremap = true })

-- Emacs like keybinding
vim.api.nvim_set_keymap('i', '<C-p>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Nop>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-p>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-n>', '<Down>', { noremap = true })

-- New tab
vim.api.nvim_set_keymap('n', 'te', ':tabedit', { noremap = true })

-- Split window
vim.api.nvim_set_keymap('n', 'ss', ':split<Return><C-w>w', { noremap = true })
vim.api.nvim_set_keymap('n', 'vs', ':vsplit<Return><C-w>w', { noremap = true })

-- Text operation
vim.api.nvim_set_keymap("v", "<Leader>j", ":s/\\({\\zs\\s\\|,\\zs\\s\\|\\s\\ze\\}\\)/\\r/g<CR>", { noremap = true })


vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])

-- colorScheme
vim.cmd.colorscheme('habamax')

-- vim.cmd.colorscheme('catppuccin')


