local status, treesitter = pcall(require, 'nvim-treesitter.configs')
if (not status) then return end

treesitter.setup {
  ensure_installed = {
    'lua',
    'css',
    'scss',
    'dockerfile',
    'gitignore',
    'html',
    'javascript',
    'json',
    'markdown',
    'tsx',
    'typescript',
    'vim',
    'vue',
    'yaml',
  },

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false, -- catpuucin用
    disable = {},
  },
	indent ={
		enable =true,
    disable ={'html'},
	},
  autotag = {
    enable = true,
  },
}
