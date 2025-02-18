local lsp = require('util.lsp')

local null_ls = require('null-ls')

null_ls.setup {
  on_attach = lsp.enable_fmt_on_attach,
  diagnostics_format = '#{m} (#{s}: #{c})',
  sources = {
    -- Prettier
    null_ls.builtins.formatting.prettier.with {
      condition = function(utils)
        return utils.has_file {
          '.prettierrc',
          '.prettierrc.js',
          '.prettierrc.cjs',
          '.prettierrc.json',
          '.prettierrc.yml',
          '.prettierrc.yaml',
        }
      end,
      prefer_local = 'node_modules/.bin',
    },

    -- Stylua
    null_ls.builtins.formatting.stylua,
  },
}
