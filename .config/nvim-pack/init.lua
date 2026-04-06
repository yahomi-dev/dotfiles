-- 高速化
if vim.loader then
  vim.loader.enable()
end

vim.cmd('autocmd!')

-- Homebrew と mise の PATH を追加
vim.env.PATH = vim.env.PATH .. ':/opt/homebrew/bin' .. ':' .. vim.fn.expand('~/.local/share/mise/shims')

-- leader キーはプラグイン読み込みより前に設定する
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- プラグイン（vim.pack）
local ok, err = pcall(require, 'plugins.init')
if not ok then
  vim.notify('plugins.init error: ' .. tostring(err), vim.log.levels.ERROR)
end

-- 基本設定
require('config.options')
require('config.keymaps')

-- LSP・TreeSitter はプラグイン読み込み後
require('config.lsp')
require('config.treesitter')

-- 日本語入力の自動切換え（macOS のみ）
if vim.fn.has('mac') == 1 then
  vim.cmd([[
    autocmd InsertLeave * silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
  ]])
end
