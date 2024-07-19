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

  --- ゴーストテキスト追加系 {{{
  {
    -- FIXME: Not work
    'haringsrob/nvim_context_vt',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'dart' },
    config = function()
      require('nvim-context-vt').setup {}
    end,
  },
  --}}}

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

  -- color scheme {{{
  { 'catppuccin/nvim' },

  {
    'Shatur/neovim-ayu',
    config = function()
      require('plugins.config.ayu')
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
  {
    -- FIXME
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    lazy = true,
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
      'nvim-telescope/telescope-fzf-native.nvim',
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

  -- Completion {{{
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-nvim-lua', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  { 'hrsh7th/cmp-path', lazy = true },
  { 'hrsh7th/cmp-cmdline', lazy = true },
  { 'hrsh7th/cmp-nvim-lsp-signature-help', lazy = true },
  { 'hrsh7th/cmp-emoji', lazy = true },
  { 'hrsh7th/cmp-calc', lazy = true },
  { 'saadparwaiz1/cmp_luasnip', lazy = true },
  { 'ray-x/cmp-treesitter', lazy = true },
  { 'uga-rosa/cmp-latex-symbol', lazy = true },
  -- {
  --   'uga-rosa/cmp-dictionary',
  --   dependencies = { 'nvim-lua/plenary.nvim' },
  --   lazy = true,
  --   config = function()
  --     require('plugins.config.cmp-dictionary')
  --   end,
  -- },
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
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
      'ray-x/cmp-treesitter',
      'uga-rosa/cmp-latex-symbol',
      -- 'uga-rosa/cmp-dictionary',
      'uga-rosa/cmp-dynamic',
      'onsails/lspkind.nvim',
    },
    config = function()
      require('plugins.config.nvim-cmp')
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

  -- {
  --   'monaqa/dial.nvim',
  --   config = function()
  --     require('plugins.config.dial')
  --   end,
  -- },

  {
    'petertriho/nvim-scrollbar',
    config = function()
      local scrollbar = require('scrollbar')
      scrollbar.setup {
        show_in_active_only = true,
        handle = {
          blend = 0,
          text = ' ',
          color = '#3b3a40',
          color_nr = 234,
        },
        marks = {
          Search = { color = '#C9A554' },
          Error = { color = '#685742' },
          Warn = { color = '#B36D43' },
          Info = { color = '#5f875f' },
          Hint = { color = '#5f875f' },
          Misc = { color = '#bb7744' },
          Cursor = { color = '#666666', text = ' ' },
        },
      }
    end,
  },

  -- neta
  { 'seandewar/nvimesweeper' },
}
