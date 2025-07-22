require('nvim-treesitter.configs').setup {
	sync_install = false,
	ensure_installed = {
		'typescript',
		'tsx',
		'javascript',
		'json',
		'vue',
		'vim',
		'lua',
		'markdown',
		'css',
		'scss',
	},
	ignore_install = { 'html' },
	additional_vim_regex_highlighting = false, -- catpuucin用
	highlight = {
		enable = true,
		disable = {},
	},
	indent = {
		enable = true,
	},
	autotag = {
		enable = true,
	},
}
