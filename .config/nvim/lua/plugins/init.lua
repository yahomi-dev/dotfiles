return {
	-- plugins manager {{{
	{ 'folke/lazy.nvim' },
	-- }}}

	-- common plugins {{{
	{ 'nvim-lua/plenary.nvim', lazy = true },

	{ 'lambdalisue/nerdfont.vim' },

	{ 'nvim-tree/nvim-web-devicons', lazy = true },

	{ 'stevearc/dressing.nvim' },

	{ 'vim-denops/denops.vim' },
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
		-- インデント補助
		'lukas-reineke/indent-blankline.nvim',
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
		config = function()
			require('ibl').setup {
				scope = { enabled = false },
			}
		end,
	},

	-- コメント
	{
		'folke/ts-comments.nvim',
		opts = {},
		event = 'VeryLazy',
		enabled = vim.fn.has('nvim-0.10.0') == 1,
	},

	-- 括弧補完、オブジェクト展開
	{
		'windwp/nvim-autopairs',
		config = function()
			require('plugins.config.nvim-autopairs')
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
		-- 閉じ括弧の行に開き括弧の情報を追加
		'haringsrob/nvim_context_vt',
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
		ft = { 'javascript', 'typescript' },
		config = function()
			require('nvim_context_vt').setup {}
		end,
	},
	--}}}

	-- 表示修正系 {{
	{
		-- 文字ごとの横幅を別に設定
		'delphinus/cellwidths.nvim',
		enabled = false,
		config = function()
			require('plugins.config.cellwidths')
		end,
	},
	-- }}

	-- カラースキーマ {{{
	{
		'catppuccin/nvim',
		config = function()
			require('plugins.config.color-theme.catppuccin')
		end,
	},

	{
		'Shatur/neovim-ayu',
		config = function()
			require('plugins.config.color-theme.ayu')
		end,
	},

	{
		'neanias/everforest-nvim',
		version = false,
		lazy = false,
		priority = 1000, -- make sure to load this before all the other start plugins
		-- Optional; default configuration will be used if setup isn't called.
		config = function()
			require('plugins.config.color-theme.everforest')
		end,
	},

	{
		'projekt0n/github-nvim-theme',
		config = function()
			require('plugins.config.color-theme.github-nvim')
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

	{
		'lambdalisue/vim-gin',
		config = function()
			require('plugins.config.vim-gin')
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
	{ import = 'plugins.config.lsp.init' },
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
	{
		'uga-rosa/cmp-dynamic',
		lazy = true,
		config = function()
			require('plugins.config.cmp-dynamic')
		end,
	},
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
		'echasnovski/mini.align',
		config = function()
			require('mini.align').setup {}
		end,
	},

	{
		'greggh/claude-code.nvim',
		config = function()
			require('plugins.config.claude-code')
		end,
	},

	-- java
	{
		'mfussenegger/nvim-jdtls',
		ft = 'java',
	},

	-- {
	--   'monaqa/dial.nvim',
	--   config = function()
	--     require('plugins.config.dial')
	--   end,
	-- },
}
