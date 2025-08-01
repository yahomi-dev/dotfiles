require('lualine').setup {
	options = {
		icons_enabled = true,
		theme = 'auto',
		component_separators = { left = '', right = '' },
		section_separators = { left = '', right = '' },
		disabled_filetypes = {},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = true,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		lualine_a = { 'mode' },
		lualine_b = { 'branch', 'diff', 'diagnostics' },
		lualine_c = {
			{
				'filename',
				path = 1,
				file_status = true,
				shorting_target = 40,

				symbols = {
					modified = ' [+]',
					readonly = ' [RO]',
					unnamed = 'Untitled',
					newfile = '[New]',
				},
			},
		},

		lualine_x = { 'filetype', 'encoding' },
		lualine_y = {
			{
				'diagnostics',
				source = { 'nvim-lsp' },
			},
		},
		lualine_z = { 'location' },
	},

	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { 'filename' },
		lualine_x = { 'location' },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	extensions = {},
}
