vim.cmd('autocmd!')

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

require('options')

require('keymaps')

require('lazy').setup('plugins')

-- colorScheme
-- vim.cmd.colorscheme('habamax')

vim.cmd.colorscheme('catppuccin')

vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])

