require('catppuccin').setup({
	flavour = 'mocha',
	background = {
		light = 'latte',
		dark = 'mocha',
	},
	transparent_background = false,
	color_overrides = {},
	integrations = {
		treesitter = true,
		native_lsp = { enabled = true },
		telescope = { enabled = true },
		gitsigns = true,
	},
})

vim.cmd('colorscheme catppuccin')
