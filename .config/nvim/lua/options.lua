
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
vim.opt.cursorline = true -- カレント行を強調
vim.opt.wrap = true -- 画面幅で折り返す
vim.opt.title = true -- タイトルを書き換える
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

