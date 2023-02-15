
vim.cmd('autocmd!')
-- Base settings
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

-- Options ------------------------------------------------------------------------------------------
vim.g.mapleader = ' '

vim.opt.history = 10000

vim.opt.confirm = true

-- Command
vim.opt.wildmenu = true -- コマンド補完を強化

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Tab
-- tabstopはTab文字を画面上で何も自分に展開するか
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Search
vim.opt.wrapscan = false -- 最後まで検索したら止まる
-- vim.opt.nowrapscan -- 最後まで検索しても先頭に戻らない
vim.opt.ignorecase = true -- 大文字小文字無視
vim.opt.smartcase = true -- 大文字ではじめたら大文字小文字無視しない
vim.opt.incsearch = true -- インクリメンタルサーチ
vim.opt.hlsearch = true -- 検索文字をハイライト

-- File
vim.opt.backup=false   -- バックアップ取らない
vim.opt.swapfile = false -- スワップファイル作らない
vim.opt.hidden = false -- 編集中の場合、他のファイルを開けない
vim.opt.autoread = true -- 他で書き換えられたら自動で読み直す

-- Otameshi


-- Display ------------------------------------------------------------------------------------------------

-- nvim color
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1

-- true color support
vim.g.colorterm = os.getenv('COLORTERM')
if vim.fn.exists('+termguicolors') == 1 then
	vim.opt.termguicolors = true
end

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


-- Emacs like keybinding
vim.keymap.set('i', '<C-f>', '<Right>')
vim.keymap.set('i', '<C-b>', '<Left>')

vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])
