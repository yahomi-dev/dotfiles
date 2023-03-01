local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- encoding
vim.o.encofing = 'utf-8'
vim.o.fileencoding = 'utf-8'
vim.scriptencoding = 'utf-8'

-- visual
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

vim.opt.laststatus = 3 -- ステータスラインが分割しないように
vim.opt.display = 'lastline' -- 長い行も一行で収まるように
vim.opt.showmode = false
vim.opt.showmatch = true -- 括弧の対応をハイライト
vim.opt.matchtime = 1 -- 括弧の対を見つけるミリ秒数
vim.opt.showcmd = true -- 入力中のコマンドを表示
vim.opt.number = true -- 行番号表示
vim.opt.wrap = true -- 画面幅で折り返す
vim.opt.title = false -- タイトル書き換えない
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.pumheight = 10 -- 補完候補の表示数
vim.opt.pumblend = 10 -- 補完候補窓の透明度
vim.opt.termguicolors = true
vim.opt.mouse = {}

-- search
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
vim.opt.undofile = false -- アンドゥファイルを作らない
vim.opt.backup = false   -- バックアップ取らない
vim.opt.swapfile = false -- スワップファイル作らない
vim.opt.hidden = false -- 編集中の場合、他のファイルを開けない
vim.opt.autoread = true -- 他で書き換えられたら自動で読み直す

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
vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', { noremap = true })


vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])

require('lazy').setup('plugins')

-- colorScheme
-- vim.cmd([[colorscheme habamax]])
vim.cmd([[colorscheme catppuccin]])

