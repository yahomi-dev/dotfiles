local function open_floating_gin(command)
  local buf = vim.api.nvim_create_buf(false, true)

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  -- Escで閉じる
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<Cmd>close<CR>', { noremap = true, silent = true })

  -- `Gin` コマンドを Floating Window 内で実行
  vim.cmd(command)
end

---- キーマッピング

vim.keymap.set('n', '<leader>gs', function()
  open_floating_gin('GinStatus')
end, { desc = 'Open GinStatus in Floating Window' })

vim.keymap.set('n', '<leader>gd', function()
  open_floating_gin('GinDiff')
end, { desc = 'Open GinDiff in Floating Window' })

vim.keymap.set('n', '<leader>gb', function()
  open_floating_gin('GinBranch')
end, { desc = 'Open GinBranch in Floating Window' })

vim.keymap.set('n', '<leader>gl', function()
  open_floating_gin('GinLog')
end, { desc = 'Open GinLog in Floating Window' })
