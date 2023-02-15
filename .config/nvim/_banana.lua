
-- Plugins

require('packer').startup(function(use)
	-- ------------------------------------------------------------
	-- Installer

	-- Plugin Manager
  use { 'wbthomason/packer.nvim' }

  -- External package Manager
  use { 'williamboman/mason.nvim' }

	-- ------------------------------------------------------------

	-- ------------------------------------------------------------
	-- common plugins
  use { 'vim-jp/vimdoc-ja' }
  use { 'nvim-lua/plenary.nvim' }
  use { 'nvim-lualine/lualine.nvim' }
  use { 'norcalli/nvim-colorizer.lua' }
  use { 'lukas-reineke/indent-blankline.nvim' }

	---------------------------------------------------------------

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }
  use { 'editorconfig/editorconfig-vim' }

  -- lsp plugins
  use { 'williamboman/mason-lspconfig.nvim' }
  use { 'neovim/nvim-lspconfig' }
  use { 'hrsh7th/nvim-cmp' }
  use { 'hrsh7th/cmp-nvim-lsp' }
  use { 'hrsh7th/cmp-buffer' }

  -- telescope
  use { 'nvim-telescope/telescope.nvim' }

  -- git information
  use 'lewis6991/gitsigns.nvim'

 -- -- buffer line
 -- use 'akinsho/bufferline.nvim', { 'tag': 'v2.*' }

 -- -- text edit
 -- use 'machakann/vim-sandwich'
 -- use 'cohama/lexima.vim'

 -- -- Fern + extensions
 -- use 'lambdalisue/fern.vim'
 -- use 'lambdalisue/nerdfont.vim'
 -- use 'lambdalisue/fern-renderer-nerdfont.vim'
 -- use 'lambdalisue/glyph-palette.vim'
 -- use 'lambdalisue/gina.vim'

end)

-- lualine
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {},
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {
      {
        'filename',
        path = 1,
        file_status = true,
        shorting_target = 40,

        symbols = {
          modified = ' [+]',
          readonly = ' [RO]',
          unnamed = 'Untitled',
          newfile = '[New]',
        }
      }
    },

    lualine_x = {'filetype', 'encoding'},
    lualine_y = {
      {
        'diagnostics',
        source = {'nvim-lsp'},
      }
    },
    lualine_z = {'location'}
    },

  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}

-- lsp configs
local mason = require('mason')
mason.setup({
 ui = {
   icons = {
     package_installed = '✓',
     package_pending = '➜',
     package_uninstalled = '✗'
   }
 }
})

local nvim_lsp = require('lspconfig')
local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup_handlers({ function(server_name)
  local opts = {}

  opts.on_attach = function(_, bufnr)
    local bufopts = { silent = true, buffer = bufnr }
    vim.keymap.set('[lsp]', 'k', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('[lsp]', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('[lsp]', 'ga', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('[lsp]', 'gtD', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('[lsp]', 'rf', vim.lsp.buf.references, bufopts)
    vim.keymap.set('[lsp]', 'f', vim.lsp.buf.format, bufopts)
  end

  nvim_lsp[server_name].setup(opts)
end })

-- cmp settings
local cmp = require('cmp')
cmp.setup({
  snippet = {},
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  },
  {
    { name = 'buffer' },
  })
})


-- - telescope
-- noremap <C-p> <cmd>Telescope find_files<cr>
-- noremap [fzf]g <cmd>Telescope live_grep<cr>
-- noremap [fzf]b <cmd>Telescope buffers<cr>
-- noremap [fzf]h <cmd>Telescope help_tags<cr>


-- treesitter
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'typescript',
    'tsx',
    'lua',
  },
  highlight = {
    enable = true,
  },
}

-- colorizer
local colorizer = require('colorizer')
colorizer.setup()


-- indent-blankline
local indent_bl = require('indent_blankline')
indent_bl.setup {
  -- for example, context is off by default, use this to turn it on
  show_current_context = true,
  show_current_context_start = true,
}


-- ayu
vim.g.ayucolor = 'mirage'

vim.cmd 'colorscheme ayu'


