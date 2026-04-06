require('nvim-treesitter').setup({
	compilers = { 'clang', 'gcc', 'cc' },
})

require('nvim-treesitter').install({
	'typescript',
	'javascript',
	'tsx',
	'html',
	'css',
	'json',
	'lua',
	'markdown',
	'markdown_inline',
	'bash',
	'vim',
	'vimdoc',
})

vim.api.nvim_create_autocmd('FileType', {
	callback = function(args)
		local ok = pcall(vim.treesitter.start, args.buf)
		if not ok then
			vim.bo[args.buf].syntax = 'on'
		end
	end,
})
