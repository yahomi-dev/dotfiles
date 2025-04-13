vim.opt.completeopt = 'menu,menuone,noselect'

vim.cmd([[set completeopt+=menuone,noselect,popup]])
vim.lsp.start {
	name = 'ts_ls',
	cmd = '',
	on_attach = function(client, bufnr)
		vim.lsp.completion.enable(true, client.id, bufnr, {
			autotrigger = true, -- 自動補完を有効にする
			convert = function(item)
				return { abbr = item.label:gsub('%b()', '') }
			end,
		})
	end,
}
