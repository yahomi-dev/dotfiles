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

require('config.options')

require('config.keymaps')

require('config.lazy')

-- colorScheme
-- vim.cmd.colorscheme('habamax')
-- vim.cmd.colorscheme('ayu')
vim.cmd.colorscheme('catppuccin')
-- vim.cmd.colorscheme('everforest')

vim.cmd([[
  :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
]])
