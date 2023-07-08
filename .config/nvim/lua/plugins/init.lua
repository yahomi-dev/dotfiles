return {
  -- plugins manager {{{
  { 'folke/lazy.nvim' },
  -- }}}

  -- common plugins {{{
  { 'nvim-lua/plenary.nvim', lazy = true },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('plugins.config.nvim-treesitter')
    end,
  },

  { 'nvim-tree/nvim-web-devicons', lazy = true },

  {
    'lukas-reineke/indent-blankline.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('indent_blankline').setup {}
    end,
  },

  { 'numToStr/Comment.nvim' },

  { 'stevearc/dressing.nvim' },

  { 'vim-jp/vimdoc-ja' },

  { 'norcalli/nvim-colorizer.lua' },

  -- 括弧補完、オブジェクト展開
  {
    'hrsh7th/nvim-insx',
    config = function()
      require('insx.preset.standard').setup {
        cmdline = {
          enabled = true,
        },
      }
    end,
  },

  { 'dkarter/bullets.vim' },
  -- }}}

  -- color scheme {{{
  { 'catppuccin/nvim' },

  {
    'andersevenrud/nordic.nvim',
    config = function()
      require('plugins.config.nordic')
    end,
  },

  { 'arcticicestudio/nord-vim' },
  -- }}}

  -- status line {{{
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('plugins.config.lualine')
    end,
  },
  -- }}}

  -- motion {{{
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    config = function()
      require('flash').setup()
    end,
  },
  -- }}}

  -- Git {{{
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('plugins.config.gitsigns')
    end,
  },
  -- }}}

  -- Fuzzy finder {{{
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('plugins.config.telescope')
    end,
  },
  -- }}}

  -- LSP setting {{{
  {
    'neovim/nvim-lspconfig',
    config = function()
      require('plugins.config.nvim-lspconfig')
    end,
  },

  { 'williamboman/mason-lspconfig.nvim', lazy = true },
  {
    'williamboman/mason.nvim',
    dependencies = { 'williamboman/mason-lspconfig.nvim' },
    build = ':MasonUpdate',
    config = function()
      require('plugins.config.mason')
    end,
  },

  {
    'jose-elias-alvarez/null-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('plugins.config.null-ls')
    end,
  },
  -- }}}

  -- Completion {{{
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-nvim-lua', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  { 'hrsh7th/cmp-path', lazy = true },
  { 'hrsh7th/cmp-cmdline', lazy = true },
  { 'hrsh7th/cmp-nvim-lsp-signature-help', lazy = true },
  { 'hrsh7th/cmp-emoji', lazy = true },
  { 'hrsh7th/cmp-calc', lazy = true },
  { 'hrsh7th/cmp-vsnip', lazy = true },
  { 'ray-x/cmp-treesitter', lazy = true },
  { 'uga-rosa/cmp-latex-symbol', lazy = true },
  {
    'uga-rosa/cmp-dictionary',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = true,
    config = function()
      require('plugins.config.cmp-dictionary')
    end,
  },
  {
    'uga-rosa/cmp-dynamic',
    lazy = true,
    config = function()
      require('plugins.config.cmp-dynamic')
    end,
  },
  { 'onsails/lspkind.nvim', lazy = true },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-emoji',
      'hrsh7th/cmp-calc',
      'hrsh7th/cmp-vsnip',
      'hrsh7th/vim-vsnip',
      'rafamadriz/friendly-snippets',
      'ray-x/cmp-treesitter',
      'uga-rosa/cmp-latex-symbol',
      'uga-rosa/cmp-dictionary',
      'uga-rosa/cmp-dynamic',
      'onsails/lspkind.nvim',
    },
    config = function()
      require('plugins.config.nvim-cmp')
    end,
  },
  -- }}}

  -- Snippet {{{
  { 'hrsh7th/vim-vsnip', lazy = true },
  { 'rafamadriz/friendly-snippets', lazy = true },
  -- }}}

  -- filer
  {
    'lambdalisue/fern.vim',
    config = function()
      require('plugins.config.fern')
    end,
  },

  { 'lambdalisue/nerdfont.vim' },
  {
    'lambdalisue/fern-renderer-nerdfont.vim',
    dependencies = {
      'lambdalisue/fern.vim',
    },
  },
  { 'lambdalisue/glyph-palette.vim' },

  -- others
  { 'machakann/vim-sandwich' },
  {
    'windwp/nvim-autopairs',
    config = function()
      require('plugins.config.nvim-autopairs')
    end,
  },

  {
    'monaqa/dial.nvim',
    config = function()
      require('plugins.config.dial')
    end,
  },
}
