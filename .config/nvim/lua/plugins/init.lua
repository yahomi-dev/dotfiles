return {
  -- plugins manager {{{
  { 'folke/lazy.nvim' },
  -- }}}

  -- common plugins {{{
  { 'nvim-lua/plenary.nvim', lazy = true },

  { 'nvim-tree/nvim-web-devicons', lazy = true },

  { 'stevearc/dressing.nvim' },
  -- }}}

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('plugins.config.nvim-treesitter')
    end,
  },

  {
    -- tsコメントをいい感じに
    'JoosepAlviste/nvim-ts-context-commentstring',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('ts_context_commentstring').setup()
    end,
  },

  {
    -- コメントいい感じに
    'numToStr/Comment.nvim',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      local ts_context = require('ts_context_commentstring.integrations.comment_nvim')

      require('Comment').setup {
        pre_hook = ts_context.create_pre_hook(),
        toggler = {
          ---Line-comment toggle keymap
          line = 'gcc',
          ---Block-comment toggle keymap
          block = '<Leader><Leader>gbc',
        },
        opleader = {
          ---Line-comment keymap
          line = 'gc',
          ---Block-comment keymap
          block = '<Leader><Leader>gb',
        },
      }
    end,
  },

  -- 括弧補完、オブジェクト展開
  {
    'hrsh7th/nvim-insx',
    config = function()
      require('insx.preset.standard').setup {
        cmdline = {
          enabled = false,
        },
      }
    end,
  },

  -- 視覚補助 {{{
  {
    -- インデント補助
    'lukas-reineke/indent-blankline.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('ibl').setup {
        scope = { enabled = false },
      }
    end,
  },

  {
    -- 括弧に色付け
    'HiPhish/rainbow-delimiters.nvim',
    config = function()
      require('plugins.config.rainbow-delimiters')
    end,
  },
  -- }}}

  -- 表示修正系 {{
  {
    -- 文字ごとの横幅を別に設定
    'delphinus/cellwidths.nvim',
    enabled = false,
    config = function()
      require('cellwidths').setup {
        name = 'default',
      }
    end,
  },
  -- }}

  -- colorscheme {{{
  {
    'catppuccin/nvim',
    config = function()
      require('plugins.config.catppuccin')
    end,
  },

  {
    'Shatur/neovim-ayu',
    config = function()
      require('plugins.config.ayu')
    end,
  },

  {
    'neanias/everforest-nvim',
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require('plugins.config.everforest')
    end,
  },
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

  -- Git {{{
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('plugins.config.gitsigns')
    end,
  },
  -- }}}

  -- Fuzzy finder {{{
  { 'fannheyward/telescope-coc.nvim' },

  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
      'fannheyward/telescope-coc.nvim',
    },

    config = function()
      require('plugins.config.telescope')
    end,
  },

  -- }}}

  --- Format / Lint {{{
  {
    'mhartington/formatter.nvim',
    config = function()
      require('plugins.config.formatter')
    end,
  },

  {
    'mfussenegger/nvim-lint',
    config = function()
      require('plugins.config.nvim-lint')
    end,
  },
  --- }}}

  -- LSP setting & Completion {{{
  {
    'neoclide/coc.nvim',
    branch = 'release',
    config = function()
      require('plugins.config.coc')
    end,
  },
  -- }}}

  -- Snippet {{{
  { 'rafamadriz/friendly-snippets', lazy = true },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'rafamadriz/friendly-snippets',
      cond = false,
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end,
    },
    version = 'v2.*',
    build = 'make install_jsregexp',
    config = function()
      vim.keymap.set('n', '<leader>ss', function()
        require('luasnip.loaders').edit_snippet_files()
      end, { desc = 'edit snippets' })
      require('luasnip.loaders.from_lua').load()
    end,
  },
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
  -- neta
  { 'seandewar/nvimesweeper' },
}
