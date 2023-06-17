local status, packer = pcall(require, "packer")
if (not status) then
  print("Packer is not installed")
  return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)

  -- Plugin Manager
  use 'wbthomason/packer.nvim'

  -- Common Plugin(Lua)
  use 'nvim-lua/plenary.nvim'
  use 'antoinemadec/FixCursorHold.nvim'

  -- colorscheme
  use { "catppuccin/nvim", as = "catppuccin" }

  -- coc.nvim
  use {'neoclide/coc.nvim', branch = 'release'}

  -- Statusline
  use 'nvim-lualine/lualine.nvim'

  -- Fern.vim
  use 'lambdalisue/fern.vim'
  use 'lambdalisue/nerdfont.vim'
  use 'lambdalisue/fern-renderer-nerdfont.vim'
  use 'lambdalisue/glyph-palette.vim'
  use 'TheLeoP/fern-renderer-web-devicons.nvim'

  use 'kyazdani42/nvim-web-devicons'

  --Syntax Highlight
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }

  -- Telescope
  use 'nvim-telescope/telescope.nvim'
  use {
    "nvim-telescope/telescope-frecency.nvim",
    requires = {"kkharji/sqlite.lua"}
  }
  use 'fannheyward/telescope-coc.nvim'

  -- Coding Support
  use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use 'lukas-reineke/indent-blankline.nvim'
  use 'numToStr/Comment.nvim'
  use 'norcalli/nvim-colorizer.lua'
  use 'simeji/winresizer'
  use 'phaazon/hop.nvim'
  use 'machakann/vim-sandwich'

  -- Rust Integration
  use 'rust-lang/rust.vim'

  -- For using Prettier
  use 'prettier/vim-prettier'

  -- Git Integration
  use 'lewis6991/gitsigns.nvim'

  -- terminal Integration
  use {
      "akinsho/toggleterm.nvim",
      tag = '*',
  }
end)
