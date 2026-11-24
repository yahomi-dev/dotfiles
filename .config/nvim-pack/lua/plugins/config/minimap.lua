local map = require('mini.map')

map.setup({
	integrations = {
		map.gen_integration.builtin_search(),
		map.gen_integration.diff(),
		map.gen_integration.diagnostic(),
	},
	window = {
		width = 10,
		winblend = 50,
	},
})

vim.keymap.set('n', '<leader>mm', MiniMap.toggle, { desc = 'Toggle minimap' })
