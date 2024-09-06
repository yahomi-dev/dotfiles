-- 高速化
if vim.loader then
  vim.loader.enable()
end

-- すべてのオートコマンドをクリア
vim.cmd('autocmd!')

-- wsl用コピペ設定
vim.cmd([[
  if system('uname -a | grep microsoft') != ''
    augroup myYank
      autocmd!
      autocmd TextYankPost * :call system('clip.exe', @")
    augroup END
  endif
]])

require('options')

require('keymaps')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins')

-- colorScheme
-- vim.cmd.colorscheme('habamax')
-- vim.cmd.colorscheme('ayu')
vim.cmd.colorscheme('catppuccin')
-- vim.cmd.colorscheme('everforest')

vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])
