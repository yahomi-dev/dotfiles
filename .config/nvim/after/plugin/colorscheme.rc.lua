vim.g.catppuccin_flavour = 'mocha' -- latte, frappe, macchiato, mocha

local status, cat = pcall(require, 'catppuccin')
if (not status) then return end

require('github-theme').setup()

cat.setup({
  color_overrides = {
    mocha = {
     -- text = '#F4CDE9',
     -- subtext1 = '#DEBAD4', -- visual-mode color
     -- subtext0 = '#C8A6BE', -- visual-mode color
     -- overlay2 = '#B293A8', -- visual-mode color
     -- overlay1 = '#9C7F92', -- visual-mode color
     -- overlay0 = '#866C7D', -- わからん！
     surface2 = '#666980', -- comment color
     -- surface1 = '#5A4551', -- visual-mode color 
     -- surface0 = '#44313B', -- current-line color 

     -- -- base = '#352939', -- back-ground color 
     -- mantle = '#211924', -- cmd-line color 
     -- crust = '#1a1016', -- わからん
    },
  },

  transparent_background = true,
  styles = {
		comments = { 'italic' },
		conditionals = { 'italic' },
    functions = {'italic'},
  },
  term_colors = true,
  integrations ={
      gitsigns = true,
      telescope = true,
			treesitter = true,
      neotree = false,
      lsp_saga = false,
      cmp = true,
			fern = true,
			indent_blankline = {
			enabled = true,
			colored_indent_levels = false,
			},
      native_lsp = {
			enabled = true,
			virtual_text = {
				errors = { 'nocombine' },
				hints = { 'nocombine' },
				warnings = { 'nocombine' },
				information = { 'nocombine' },
			},
			underlines = {
				errors = { 'undercurl' },
				hints = { 'undercurl' },
				warnings = { 'undercurl' },
				information = { 'undercurl' },
			},
      },
},
})
-- colorschemeをセットする際に、vim.opt.list=falseにしておかないとタブ文字の色が目立つ
vim.cmd([[colorscheme catppuccin]])


-- vim.cmd([[colorscheme 'github-theme']])
