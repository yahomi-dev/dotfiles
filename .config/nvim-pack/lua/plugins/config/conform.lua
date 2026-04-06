require('conform').setup({
	formatters_by_ft = {
		lua             = { 'stylua' },
		typescript      = { 'biome' },
		javascript      = { 'biome' },
		typescriptreact = { 'biome' },
		javascriptreact = { 'biome' },
		json            = { 'biome' },
		jsonc           = { 'biome' },
		html            = { 'biome' },
		css             = { 'biome' },
	},

	format_on_save = function(bufnr)
		local buf_path = vim.api.nvim_buf_get_name(bufnr)
		if buf_path == '' then return nil end

		local ft = vim.bo[bufnr].filetype
		local ok, projects = pcall(require, 'config.formatter_projects')

		if ok then
			for project_root, config in pairs(projects) do
				if vim.startswith(buf_path, project_root) then
					if not config.enabled then
						return nil
					end
					if config.formatters_by_ft and config.formatters_by_ft[ft] then
						return {
							timeout_ms = 500,
							lsp_format = 'fallback',
							formatters = config.formatters_by_ft[ft],
						}
					end
					break
				end
			end
		end

		return { timeout_ms = 500, lsp_format = 'fallback' }
	end,
})

-- 手動フォーマット
vim.keymap.set({ 'n', 'v' }, '<leader>fm', function()
	require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer' })

-- フォーマットせずに保存
vim.keymap.set('n', '<leader>W', '<cmd>noautocmd w<CR>', { desc = 'Save without format' })
