require('base');

if vim.g.vscode == 1 then
  require('vscode')
  return
end

require('plugins');

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

