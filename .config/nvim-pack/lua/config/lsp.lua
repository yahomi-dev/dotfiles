local servers = {
	'vtsls',
	'html',
	'cssls',
	'lua_ls',
	'biome',
	'tailwindcss',
	'jsonls',
}

require('mason').setup()
require('mason-lspconfig').setup({ ensure_installed = servers })

-- blink.cmp の capabilities を全サーバにグローバル適用
local ok, blink = pcall(require, 'blink.cmp')
if ok then
	vim.lsp.config('*', {
		capabilities = blink.get_lsp_capabilities(
			vim.lsp.protocol.make_client_capabilities()
		),
	})
end

-- 個別設定
vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			diagnostics = { globals = { 'vim' } },
			workspace = { checkThirdParty = false },
		},
	},
})

vim.lsp.config('vtsls', {
	settings = {
		typescript = {
			updateImportsOnFileMove = { enabled = 'always' },
		},
	},
})

vim.lsp.config('jsonls', {
	settings = {
		json = {
			validate = { enable = true },
		},
	},
})

vim.lsp.config('biome', {
	root_markers = { 'biome.json', 'biome.jsonc' },
})

-- インレイヒント有効化
vim.lsp.inlay_hint.enable(true)

-- 診断設定
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

if next(servers) then
	vim.lsp.enable(servers)
end
