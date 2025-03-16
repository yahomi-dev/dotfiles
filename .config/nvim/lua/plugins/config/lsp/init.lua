return {
	{
		'neovim/nvim-lspconfig',
		event = { 'BufReadPost', 'BufNewFile' },
		cmd = { 'LspInfo', 'LspInstall', 'LspUninstall' },
		dependencies = {
			{ 'williamboman/mason.nvim' },
			{ 'williamboman/mason-lspconfig.nvim' },
			{ 'b0o/schemastore.nvim' },
		},
		config = function()
			require('plugins.config.lsp.diagnostic')
			require('plugins.config.lsp.format')
			require('plugins.config.lsp.attach')
			require('plugins.config.lsp.server-register')
		end,
	},

	{ import = 'plugins.config.lsp.conform' },
}
