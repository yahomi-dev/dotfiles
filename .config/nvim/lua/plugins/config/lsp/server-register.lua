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
	'rust_analyzer',
	'solidity_ls',
	'tailwindcss',
	'ts_ls',
	'volar',
}

local mason_lspconfig = require('mason-lspconfig')

require('mason-lspconfig').setup {
	ensure_installed = ensure_installed,
}

mason_lspconfig.setup_handlers {
	function(server_name)
		require('lspconfig')[server_name].setup {
			settings = {
				Lua = {
					diagnostics = {
						globals = { 'vim' },
					},
				},
				json = {
					schemas = require('schemastore').json.schemas(),
					validate = { enable = true },
				},
				jsonc = {
					schemas = require('schemastore').json.schemas(),
					validate = { enable = true },
				},
			},
		}
	end,
}
