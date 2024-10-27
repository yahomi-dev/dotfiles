return {
  -- plugins manager {{{
  { 'folke/lazy.nvim' },
  -- }}}

  -- common plugins {{{
  { 'nvim-lua/plenary.nvim', lazy = true },
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
    -- コメントをいい感じに
    'JoosepAlviste/nvim-ts-context-commentstring',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('ts_context_commentstring').setup()
    end,
  },

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
    -- コメントいい感じに
    'numToStr/Comment.nvim',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('Comment').setup {
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
          enabled = true,
        },
      }
    end,
  },

  -- ハイライト系 {{{

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

  -- others
  { 'machakann/vim-sandwich' },
  {
    'windwp/nvim-autopairs',
    config = function()
      require('plugins.config.nvim-autopairs')
    end,
  },
}
