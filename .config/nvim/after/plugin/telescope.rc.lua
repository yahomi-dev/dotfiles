local status, telescope = pcall(require, "telescope")
if (not status) then return end

local builtin = require('telescope.builtin')

telescope.setup({
  defaults ={
      layout_strategy = 'vertical',
      layout_config = { height = 0.9,width = 0.9 },
  },
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

vim.keymap.set('n', ',o', function()
  builtin.oldfiles({hidden = true})
end)

vim.keymap.set('n', 'zb', function()
  builtin.buffers({hidden = true})
end)
