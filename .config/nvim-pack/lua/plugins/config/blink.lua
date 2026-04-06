require('blink.cmp').setup({
	keymap = {
		preset = 'enter',
		['<C-n>'] = { 'select_next', 'fallback' },
		['<C-p>'] = { 'select_prev', 'fallback' },
	},
	appearance = {
		nerd_font_variant = 'mono',
	},
	sources = {
		default = { 'lsp', 'path', 'snippets', 'buffer' },
	},
	completion = {
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 300,
		},
	},
	snippets = { preset = 'default' },
	fuzzy = { implementation = 'lua' },
})
