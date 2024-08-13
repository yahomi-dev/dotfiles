-- Utilities for creating configurations
local util = require('formatter.util')

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require('formatter').setup {
  -- Enable or disable logging
  logging = true,

  -- Set the log level
  log_level = vim.log.levels.WARN,

  -- All formatter configurations are opt-in
  filetype = {
    javascript = {
      function()
        return {
          exe = 'prettier',
          args = {
            '--stdin-filepath',
            vim.api.nvim_buf_get_name(0),
          },
          stdin = true,
        }
      end,
    },

    typescript = {
      function()
        return {
          exe = 'prettier',
          args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },

    typescriptreact = {
      function()
        return {
          exe = 'prettier',
          args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },

    -- Formatter configurations for filetype "lua" go here
    -- and will be executed in order
    lua = {
      -- "formatter.filetypes.lua" defines default configurations for the
      -- "lua" filetype
      require('formatter.filetypes.lua').stylua,

      -- You can also define your own configuration
      function()
        -- Supports conditional formatting
        if util.get_current_buffer_file_name() == 'special.lua' then
          return nil
        end

        -- Full specification of configurations is down below and in Vim help
        -- files
        return {
          exe = 'stylua',
          args = {
            '--search-parent-directories',
            '--stdin-filepath',
            util.escape_path(util.get_current_buffer_file_path()),
            '--',
            '-',
          },
          stdin = true,
        }
      end,
    },

    -- Use the special "*" filetype for defining formatter configurations on
    -- any filetype
    ['*'] = {
      -- "formatter.filetypes.any" defines default configurations for any
      -- filetype
      require('formatter.filetypes.any').remove_trailing_whitespace,
    },
  },
}

-- format
vim.api.nvim_set_keymap('n', '<Leader>fm', '<cmd>Format<CR>', { noremap = true })

-- 自動的に保存時にフォーマットを実行
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { '*.lua', '*.js', '*.tsx' },
  callback = function()
    vim.cmd('FormatWrite')
  end,
})

-- lspで動くものはこっちだけで動く
-- ref: https://eiji.page/blog/neovim-dynamic-capabilities/
-- ref2: https://github.com/neovim/nvim-lspconfig/issues/1792#issuecomment-1352782205
-- vim.api.nvim_set_keymap('n', '<leader>fm', '<cmd>lua vim.lsp.buf.format({timeout = 2000})<CR>', { noremap = true })
