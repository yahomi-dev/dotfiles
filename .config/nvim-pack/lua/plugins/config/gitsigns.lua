require('gitsigns').setup {
  signs = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  attach_to_untracked = true,
  current_line_blame = false,
  on_attach = function(bufnr)
    local gs = require('gitsigns')
    local map = function(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- ナビゲーション
    map('n', ']h', function()
      gs.nav_hunk('next')
    end, { desc = 'Next hunk' })
    map('n', '[h', function()
      gs.nav_hunk('prev')
    end, { desc = 'Prev hunk' })

    -- アクション
    map('n', '<leader>hs', gs.stage_hunk, { desc = 'Stage hunk' })
    map('v', '<leader>hs', function()
      gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
    end, { desc = 'Stage hunk (visual)' })

    map('n', '<leader>hr', gs.reset_hunk, { desc = 'Reset hunk' })
    map('v', '<leader>hr', function()
      gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
    end, { desc = 'Reset hunk (visual)' })

    map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
    map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
    map('n', '<leader>hb', function()
      gs.blame_line { full = true }
    end, { desc = 'Blame line (full)' })
  end,
}
