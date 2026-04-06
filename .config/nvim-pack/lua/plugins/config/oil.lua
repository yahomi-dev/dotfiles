require('oil').setup({
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
	float = {
		padding = 2,
		max_width = 80,
		max_height = 30,
	},
	keymaps = {
		['<C-s>'] = false,
		['<C-h>'] = false,
		['<C-p>'] = false,
	},
})

vim.keymap.set('n', '-', ':Oil --float<CR>', { desc = 'Open file explorer (oil float)' })
vim.keymap.set('n', '<leader>-', ':Oil<CR>', { desc = 'Open file explorer (oil split)' })
