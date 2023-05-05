local status,hop = pcall(require, "hop")
if (not status) then return end

vim.api.nvim_set_keymap('n', '<leader><leader>', ':HopWord<CR>', { noremap = true })

require('hop').setup {
  keys = 'etovxqpdygfblzhckisuran'
}
