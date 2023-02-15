local status, packer = pcall(require, "packer")
if (not status) then
  print("Packer is not installed")
  return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)

  use 'wbthomason/packer.nvim'

	-- common plugins
  use { 'vim-jp/vimdoc-ja' }
  use { 'nvim-lua/plenary.nvim' }
  use { 'nvim-lualine/lualine.nvim' }
  use { 'norcalli/nvim-colorizer.lua' }
  use { 'lukas-reineke/indent-blankline.nvim' }

	-- ColorScheme
  use 'sainnhe/everforest'
  use { "catppuccin/nvim", as = "catppuccin" } -- colorscheme
  use ({ "projekt0n/github-nvim-theme", as = 'github-theme'}) --colorscheme

  -- 追加した
  use 'rmehri01/onenord.nvim'


  use 'lambdalisue/nerdfont.vim'

  use 'lambdalisue/fern.vim'
  use 'lambdalisue/fern-renderer-nerdfont.vim'
  use 'lambdalisue/glyph-palette.vim'

  use {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  }

  -- use 'j-hui/fidget.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  -- use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'

  -- vsnip exensions for react.
  use "rafamadriz/friendly-snippets"

  use 'onsails/lspkind.nvim'

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }

  use 'kyazdani42/nvim-web-devicons'

  -- Linter + Formatter
  use({
    "jose-elias-alvarez/null-ls.nvim",
    requires = { "nvim-lua/plenary.nvim" },
  })

  -- use 'MunifTanjim/prettier.nvim'

  use({
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { "nvim-lua/plenary.nvim" },
  })

  use 'windwp/nvim-autopairs'
  use "terrortylor/nvim-comment"
  use 'machakann/vim-sandwich'
  -- use 'mattn/emmet-vim'

  use 'lewis6991/gitsigns.nvim'

end)

