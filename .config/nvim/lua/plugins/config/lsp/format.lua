vim.api.nvim_create_user_command('FormatDisable', function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = 'Disable autoformat-on-save',
	bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = 'Re-enable autoformat-on-save',
})

-- ref: https://zenn.dev/izumin/articles/b8046e64eaa2b5
local function code_action_sync(client, bufnr, cmd)
	-- https://github.com/golang/tools/blob/gopls/v0.11.0/gopls/doc/vim.md#imports
	local params = vim.lsp.util.make_range_params()
	params.context = { only = { cmd }, diagnostics = {} }
	-- gopls のドキュメントでは `vim.lsp.buf_request_sync` を使っているが、
	-- ここでは対象 Language Server を1つに絞るために `vim.lsp.Client` の `request_sync` を使う
	local res = client.request_sync('textDocument/codeAction', params, 3000, bufnr)
	for _, r in pairs(res and res.result or {}) do
		if r.edit then
			local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
			vim.lsp.util.apply_workspace_edit(r.edit, enc)
		end
	end
end

local function organize_imports_sync(client, bufnr)
	code_action_sync(client, bufnr, 'source.organizeImports')
end

local save_handlers_by_client_name = {
	biome = { organize_imports_sync },
}

vim.api.nvim_create_autocmd('LspAttach', {
	group = require('util.augroup').lsp_group,
	callback = function()
		vim.api.nvim_create_autocmd('BufWritePre', {
			pattern = '*',
			callback = function(args)
				local bufnr = args.buf
				local shouldSleep = false

				for _, client in pairs(vim.lsp.get_clients { bufnr = bufnr }) do
					local save_handlers = save_handlers_by_client_name[client.name]

					for _, f in pairs(save_handlers or {}) do
						if shouldSleep then
							vim.api.nvim_command('sleep 10ms')
						else
							shouldSleep = true
						end

						f(client, bufnr)
					end
				end

				require('conform').format {
					bufnr = args.buf,
					lsp_fallback = true,
					filter = function(client)
						return client.name ~= 'ts_ls'
					end,
				}
			end,
		})
	end,
})
