vim.g['fern#renderer'] = 'nerdfont'
vim.g['fern#default_hidden'] = true
vim.g['fern#renderer#nerdfont#indent_markers'] = true
vim.g['fern#hide_cursor'] = true

vim.keymap.set('n', '<leader>e', ':<C-u>Fern . -drawer -reveal=% -width=40 -toggle -keep<CR>',
	{ silent = true, desc = 'Toggle file explorer (fern)' })

vim.api.nvim_create_augroup('my-glyph-palette', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
	group = 'my-glyph-palette',
	pattern = { 'fern', 'nerdtree', 'startify' },
	callback = function()
		vim.fn['glyph_palette#apply']()
	end,
})

-- fern ウィンドウの背景色だけ暗くする
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'fern',
	callback = function()
		vim.api.nvim_set_hl(0, 'FernNormal', { bg = '#11111b' })
		vim.wo.winhighlight = 'Normal:FernNormal'
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'fern',
	callback = function(args)
		vim.opt_local.relativenumber = false
		vim.opt_local.number = false
		vim.opt_local.signcolumn = 'no'
		vim.opt_local.foldcolumn = '0'

		local opts = { buffer = args.buf, silent = true }

		-- 単体コピー
		vim.keymap.set('n', 'yy', '<Plug>(fern-action-yank:path)', opts)
		vim.keymap.set('n', 'yn', '<Plug>(fern-action-yank:label)', opts)

		-- マーク（m でトグル）
		vim.keymap.set('n', 'm', '<Plug>(fern-action-mark:toggle)j', opts)

		-- マークした複数ファイルのパスをまとめてコピー
		vim.keymap.set('n', 'Y', function()
			vim.cmd([[
				let s:helper = fern#helper#new()
				let s:nodes = s:helper.sync.get_selected_nodes()
				if empty(s:nodes)
					echo 'No marked files'
				else
					let s:paths = []
					for s:node in s:nodes
						let s:path = s:node['_path']
						if isdirectory(s:path)
							let s:path = s:path . '/'
						endif
						call add(s:paths, s:path)
					endfor
					call setreg('+', join(s:paths, "\n"))
					echo 'Copied ' . len(s:paths) . ' paths'
				endif
			]])
			-- マークを解除
			vim.fn.feedkeys(
				vim.api.nvim_replace_termcodes('<Plug>(fern-action-mark:clear)', true, false, true),
				'x'
			)
		end, opts)
	end,
})
