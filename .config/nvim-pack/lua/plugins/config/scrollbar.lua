require('scrollbar').setup({
	show_in_active_only = false,
	handle = {
		color = '#3b4261',
	},
	marks = {
		Search    = { color = '#ff9e64' },
		Error     = { color = '#f7768e' },
		Warn      = { color = '#e0af68' },
		Info      = { color = '#0db9d7' },
		Hint      = { color = '#1abc9c' },
		GitAdd    = { color = '#9ece6a' },
		GitChange = { color = '#7aa2f7' },
		GitDelete = { color = '#f7768e' },
	},
	handlers = {
		gitsigns   = true,
		diagnostic = true,
	},
})
