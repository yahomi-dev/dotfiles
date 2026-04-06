local telescope = require('telescope')
local builtin = require('telescope.builtin')

local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    -- sorting_strategy = 'ascending',
    winblend = 25,
    layout_strategy = 'horizontal',
    layout_config = {
      preview_cutoff = 99,
      height = 0.99,
      width = 0.99,
    },

    --検索対象に含めないファイルを指定
    file_ignore_patterns = {
      '^.git/',
      '^node_modules/',
    },

    -- キーマップ
    mappings = {
      i = {
        ['<Esc>'] = actions.close,
      },
      n = {
        ['q'] = actions.close,
      },
    },
  },
}

-- fzf-native が入っていれば有効化
pcall(telescope.load_extension, 'fzf')

local map = vim.keymap.set
map('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
map('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
map('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
map('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
map('n', '<leader>fd', builtin.diagnostics, { desc = 'Diagnostics' })
map('n', '<leader>fr', builtin.lsp_references, { desc = 'LSP references' })
map('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Document symbols' })

map('n', '<C-p>', function()
  builtin.find_files { no_ignore = false, hidden = true }
end)
map('n', 'zf', function()
  builtin.live_grep {
    hidden = true,
    additional_args = function()
      return { '--hidden' }
    end,
  }
end)
map('n', 'zo', function()
  builtin.oldfiles { hidden = true }
end)
map('n', 'zb', function()
  builtin.buffers { hidden = true }
end)
map('n', 'zgs', builtin.git_status, { desc = 'Git status' })
map('n', 'zgb', builtin.git_branches, { desc = 'Git branches' })
