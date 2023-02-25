return {
  'nvim-treesitter/nvim-treesitter',
  config = function()
    require('nvim-treesitter.configs').setup {
      sync_install = false,
      ensure_installed = {
        'typescript',
        'javascript',
        'vue',
        'vim',
        'lua',
      },
      ignore_install = { 'html' },
      highlight = {
        enable = true,
        disable = {},
      },
      indent ={
        enable =true
      },
      autotag = {
        enable = false,
      }
    }
  end
}
