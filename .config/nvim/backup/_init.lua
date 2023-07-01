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

require('base')

-- ===============================

require('keymaps')

require('lazy').setup({
  -- common plugins
  'vim-jp/vimdoc-ja' ,
  'nvim-lua/plenary.nvim',
  'nvim-lualine/lualine.nvim',
  'norcalli/nvim-colorizer.lua',
  'lukas-reineke/indent-blankline.nvim',
  'lewis6991/gitsigns.nvim',
  'numToStr/Comment.nvim',
  'stevearc/dressing.nvim',
  'nvim-tree/nvim-web-devicons',

  -- color scheme
  {'catppuccin/nvim', name = 'catppuccin'},

  -- lsp setting
  'neovim/nvim-lspconfig',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig',
  'tami5/lspsaga.nvim',
  'onsails/lspkind-nvim',
  'ray-x/lsp_signature.nvim',
  'j-hui/fidget.nvim',

  -- cmp sources
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',

  -- formatter
  'jose-elias-alvarez/null-ls.nvim',
  'jayp0521/mason-null-ls.nvim',

  -- filer
  {
    'lambdalisue/fern.vim',
    config = function()
      require('rc/fern')
    end
  },
  {
    'lambdalisue/fern-renderer-nerdfont.vim',
    dependencies = {
      'lambdalisue/fern.vim'
    },
  },
  'lambdalisue/nerdfont.vim',
  'lambdalisue/glyph-palette.vim',

  -- others
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('rc/telescope')
    end
  },
  'nvim-treesitter/nvim-treesitter',
})

