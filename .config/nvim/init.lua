-- 高速化
if vim.loader then
	vim.loader.enable()
end

-- すべてのオートコマンドをクリア
vim.cmd('autocmd!')

if vim.g.vscode then
	-- VS Code用の設定ディレクトリにあるinit.luaを読み込み
	vim.opt.rtp:prepend(vim.fn.stdpath('config') .. '/vscode_config')
	dofile(vim.fn.stdpath('config') .. '/vscode_config/init.lua')
else
	require('config.options')

	require('config.keymaps')

	require('config.lazy')

	-- colorScheme
	-- vim.cmd.colorscheme('habamax')
	-- vim.cmd.colorscheme('ayu')
	vim.cmd.colorscheme('catppuccin')
	-- vim.cmd.colorscheme('everforest')
	-- vim.cmd('colorscheme github_dark')

	vim.cmd([[
    :autocmd InsertLeave * :silent !/opt/homebrew/bin/im-select com.apple.keylayout.ABC
  ]])
end
