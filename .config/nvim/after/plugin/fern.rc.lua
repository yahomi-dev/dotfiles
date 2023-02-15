vim.cmd([[
let g:fern#renderer = "nerdfont"

let g:fern#default_hidden=1

nnoremap <silent> <Leader>e :<C-u>Fern . -drawer -reveal=% -width=40 -toggle -keep<CR>

augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END
]])
