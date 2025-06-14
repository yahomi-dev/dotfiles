local claudeCode = require('claude-code')

claudeCode.setup {}

vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>')
