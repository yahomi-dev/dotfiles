-- encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'
vim.scriptencoding = 'utf-8'

-- visual
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 500
vim.opt.laststatus = 3
vim.opt.display = 'lastline'
vim.opt.showmode = false
vim.opt.showmatch = true
vim.opt.matchtime = 1
vim.opt.showcmd = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = false
vim.opt.wrap = true
vim.opt.title = false
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 5
vim.opt.termguicolors = true
vim.opt.mouse = {}

-- search
vim.opt.wrapscan = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- clipboard
vim.opt.clipboard = 'unnamedplus'

-- timing
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 50

-- file
vim.opt.confirm = true
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.hidden = false
vim.opt.autoread = true

-- completion
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
