return {
  'glepnir/template.nvim',
  cmd = {'Template','TemProject'},
  config = function()
    require('template').setup({
      opts = {
        temp_dir = '~/.config/nvim/template'
      }
    })
  end
}
