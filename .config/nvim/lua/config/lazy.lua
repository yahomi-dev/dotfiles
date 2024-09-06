-- https://lazy.folke.io/installation
-- {{{
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)
-- }}}

-- Setup lazy.nvim
require('lazy').setup {
  -- lua/pluginsの内容を読み込み
  spec = {
    { import = 'plugins' },
  },

  -- インストール画面でのカラースキーマ
  install = { colorscheme = { 'catppuccin' } },

  -- プラグインの自動更新確認
  checker = { enabled = false },
}
