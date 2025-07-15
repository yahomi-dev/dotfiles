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

local servers = {
	'biome',
	'lua_ls',
	'jsonls',
	'rust_analyzer',
	'cssls',
	'tailwindcss',
	'vtsls',
	'volar',
	'prismals',
}

vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			diagnostics = {
				globals = { 'vim' },
			},
			format = {
				enable = false, -- Use StyLua
			},
		},
	},
})

vim.lsp.inlay_hint.enable(true)

if next(servers) then
	vim.lsp.enable(servers)
end
