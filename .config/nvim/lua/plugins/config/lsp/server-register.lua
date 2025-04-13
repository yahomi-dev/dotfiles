require('mason').setup {
	ui = {
		border = 'rounded',
		icons = {
			package_installed = '✓',
			package_pending = '➜',
			package_uninstalled = '✗',
		},
	},
}

local ensure_installed = {
	'biome',
	'cssls',
	'jsonls',
	'lua_ls',
	'prismals',
	'rust_analyzer',
	'solidity_ls',
	'tailwindcss',
	'ts_ls',
	'volar',
	'vtsls',
}

require('mason-lspconfig').setup {
	automatic_installation = true,
	ensure_installed = ensure_installed,
}

vim.lsp.enable(ensure_installed)
