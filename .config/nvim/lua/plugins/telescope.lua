return {
  'nvim-telescope/telescope.nvim', tag = '0.1.1',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')

    require('telescope').setup({
      defaults ={
        layout_strategy = 'vertical',
        layout_config = { height = 0.9,width = 0.9 },
        mappings = {
          n = {
            ['q'] = actions.close
          }
        }
      }
    })

    vim.keymap.set('n', '<C-p>',
      function()
        builtin.find_files({
          no_ignore = false,
          hidden = true
        })
      end)

    vim.keymap.set('n', 'zf', function()
      builtin.live_grep({hidden = true})
    end)

    vim.keymap.set('n', 'zo', function()
      builtin.oldfiles({hidden = true})
    end)

    vim.keymap.set('n', 'zb', function()
      builtin.buffers({hidden = true})
    end)

    vim.keymap.set('n', ';e', function()
      builtin.diagnostics()
    end)
  end
}
