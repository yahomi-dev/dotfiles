vim.cmd([[
let g:fern#renderer = "nerdfont"

let g:fern#default_hidden=1
let g:fern#renderer#nerdfont#indent_markers=1
augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

]])

local opt = {silent = true,noremap = true}

vim.keymap.set('n','<Leader>e',':Fern . -drawer -reveal=% -width=40 -toggle -keep <CR>', opt)
