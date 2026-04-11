local notes_dir = vim.fn.fnamemodify(vim.env.MYVIMRC or '', ':h') .. '/notes'

-- MYVIMRC が未設定の場合のフォールバック
if notes_dir == '/notes' then
	notes_dir = vim.fn.stdpath('config') .. '/notes'
end

local map = vim.keymap.set

-- ノート一覧を開く
map('n', '<leader>no', function()
	require('telescope.builtin').find_files({
		prompt_title = 'Notes',
		cwd = notes_dir,
		hidden = false,
	})
end, { desc = 'Open note' })

-- ノート内を全文検索
map('n', '<leader>nf', function()
	require('telescope.builtin').live_grep({
		prompt_title = 'Search Notes',
		cwd = notes_dir,
	})
end, { desc = 'Find in notes' })

-- 新規ノート作成
map('n', '<leader>nn', function()
	vim.ui.input({ prompt = 'Note name: ' }, function(name)
		if not name or name == '' then return end
		if not name:match('%.md$') then name = name .. '.md' end
		vim.cmd('edit ' .. notes_dir .. '/' .. name)
	end)
end, { desc = 'New note' })
