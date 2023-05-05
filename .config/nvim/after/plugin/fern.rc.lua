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

-- 下記の記述はtrash-cliを用いない場合にファイル等を削除する方法
-- ただし内部的には $ rm のため、原則使わない

-- function! s:fern_settings() abort
--   nmap <silent> <buffer> dd <Plug>(fern-action-remove)
-- endfunction

-- augroup fern-settings
--   autocmd!
--   autocmd FileType fern call s:fern_settings()
-- augroup END
