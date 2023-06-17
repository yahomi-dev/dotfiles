 require("catppuccin").setup({
     flavour = "macchiato", -- latte, frappe, macchiato, mocha
     background = { -- :h background
         light = "latte",
         dark = "mocha",
     },
     transparent_background = true,
     show_end_of_buffer = false, -- show the '~' characters after the end of buffers
     term_colors = true,
     dim_inactive = {
         enabled = false,
         shade = "dark",
         percentage = 0.15,
     },
     no_italic = false, -- Force no italic
     no_bold = false, -- Force no bold
     styles = {
         comments = {  },
         conditionals = { "italic" },
         loops = {},
         functions = {"italic"},
         keywords = {},
         strings = {},
         variables = {},
         numbers = {},
         booleans = {},
         properties = {},
         types = {},
         operators = {},
     },
     color_overrides = {},
     custom_highlights = {},
     integrations = {
         gitsigns = true,
         nvimtree = true,
         coc_nvim = false,
         telescope = true,
         notify = false,
         mini = false,
         fern = true,
         indent_blankline = {
         enabled = true,
         colored_indent_levels = false,
 		},

         -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
     },
 })

vim.cmd.colorscheme "catppuccin"
