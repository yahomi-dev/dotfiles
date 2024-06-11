vim.cmd('autocmd!')

-- encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.scriptencoding = 'utf-8'

-- visual
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 500
vim.opt.laststatus = 3 -- ステータスラインが分割しないように
vim.opt.display = 'lastline' -- 長い行も一行で収まるように
vim.opt.showmode = false -- モード表示をOFF(luaLineにて表示)
vim.opt.showmatch = true -- 括弧の対応をハイライト
vim.opt.matchtime = 1 -- 括弧の対を見つけるミリ秒数
vim.opt.showcmd = true -- 入力中のコマンドを表示
vim.opt.number = false -- 行番号表示
vim.opt.cursorline = false -- カレント行を強調しない trueにすると重くなる
vim.opt.wrap = true -- 画面幅で折り返す
vim.opt.title = false -- タイトルを書き換えない
vim.opt.scrolloff = 5 -- スクロール時の上下padding付与
vim.opt.sidescrolloff = 5 -- (opt.wrap=trueなので横はスクロールしない)
vim.opt.completeopt = 'noinsert' -- 補完選択しない限り反映されないように
vim.opt.pumheight = 10 -- 補完候補の表示数
vim.opt.pumblend = 10 -- 補完候補窓の透明度
vim.opt.winblend = 5 -- 透明度
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
vim.opt.hidden = false -- 編集中の場合、他のファイルを開けない
vim.opt.autoread = true -- 他で書き換えられたら自動で読み直す

-- -- LSPの警告フォーマット
-- -- ref: https://dev.classmethod.jp/articles/eetann-change-neovim-lsp-diagnostics-format/
-- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
--   virtual_text = {
--     format = function(diagnostic)
--       if not diagnostic.source then
--         return diagnostic.message
--       end
--
--       return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
--     end,
--   },
-- })



