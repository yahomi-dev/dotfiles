local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    -- sorting_strategy = 'ascending',
    winblend = 4,
    layout_strategy = 'vertical',
    layout_config = {
      height = 0.9,
      width = 0.9,
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

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', function()
  builtin.find_files {
    no_ignore = false,
    hidden = true,
  }
end)

vim.keymap.set('n', 'zf', function()
  builtin.live_grep {
    hidden = true,
    additional_args = function()
      return { '--hidden' }
    end,
  }
end)

vim.keymap.set('n', 'zo', function()
  builtin.oldfiles { hidden = true }
end)

vim.keymap.set('n', 'zb', function()
  builtin.buffers { hidden = true }
end)

vim.keymap.set('n', 'zgs', function()
  builtin.git_status()
end)

-- git branch
vim.keymap.set('n', 'zgb', function()
  builtin.git_branches()
end)
