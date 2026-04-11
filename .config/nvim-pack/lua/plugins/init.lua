vim.pack.add {
  -- 依存ライブラリ
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/MunifTanjim/nui.nvim',

  -- UI 改善
  'https://github.com/stevearc/dressing.nvim',

  -- 編集補助
  'https://github.com/folke/ts-comments.nvim',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/machakann/vim-sandwich',
  'https://github.com/lukas-reineke/indent-blankline.nvim',
  'https://github.com/echasnovski/mini.align',

  -- Telescope 高速化（インストール後に手動で make が必要）
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',

  -- LSP
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/williamboman/mason.nvim',
  'https://github.com/williamboman/mason-lspconfig.nvim',

  -- TreeSitter（main ブランチ必須）
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', branch = 'main' },

  -- 補完
  'https://github.com/rafamadriz/friendly-snippets',
  'https://github.com/saghen/blink.cmp',

  -- カラースキーム
  'https://github.com/catppuccin/nvim',

  -- UI
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/stevearc/oil.nvim',

  -- ファイラー（fern）
  'https://github.com/lambdalisue/vim-fern',
  'https://github.com/lambdalisue/vim-nerdfont',
  'https://github.com/lambdalisue/vim-fern-renderer-nerdfont',
  'https://github.com/lambdalisue/vim-glyph-palette',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/petertriho/nvim-scrollbar',
  'https://github.com/stevearc/conform.nvim',
}

-- プラグインが存在するときだけ設定を読み込む
local function safe_require(mod)
  local ok, err = pcall(require, mod)
  if not ok then
    vim.notify('Failed to load ' .. mod .. ': ' .. err, vim.log.levels.WARN)
  end
end

safe_require('plugins.config.catppuccin')
safe_require('plugins.config.blink')
safe_require('plugins.config.lualine')
safe_require('plugins.config.oil')
safe_require('plugins.config.fern')
safe_require('plugins.config.telescope')
safe_require('plugins.config.gitsigns')
safe_require('plugins.config.scrollbar')
safe_require('plugins.config.conform')

-- ts-comments は setup のみ（設定ファイル不要）
local ok_tsc = pcall(require, 'ts-comments')
if ok_tsc then
  require('ts-comments').setup {}
end

safe_require('plugins.config.dressing')
safe_require('plugins.config.autopairs')
safe_require('plugins.config.ibl')
safe_require('plugins.config.mini-align')
safe_require('plugins.config.notes')
