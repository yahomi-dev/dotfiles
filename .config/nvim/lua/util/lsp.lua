local M = {}

M.ft = {}

M.ft.js_like = {
  'javascript',
  'javascriptreact',
  'javascript.jsx',
  'typescript',
  'typescriptreact',
  'typescript.tsx',
}

M.ft.node_specific_files = {
  'node_modules',
  'bun.lockb', -- bun
  'package-lock.json', -- npm or bun
  'npm-shrinkwrap.json', -- npm
  'yarn.lock', -- yarn
  'pnpm-lock.yaml', -- pnpm
}

M.ft.node_files = vim
  .iter({
    M.ft.node_specific_files,
    'package.json',
  })
  :flatten(math.huge)
  :totable()

function M.is_files_found(path, files)
  return vim.iter(files):any(function(file)
    return vim.uv.fs_stat(vim.fs.joinpath(path, file)) ~= nil
  end)
end

-- ref:
-- https://github.com/ryoppippi/dotfiles/blob/e6e0f02/nvim/lua/plugin/nvim-lspconfig/servers/vtsls.lua#L44-L70
function M.find_node_root(path)
  if path == nil then
    return nil
  end

  local project_root = vim.fs.root(path, M.ft.node_specific_files)

  if project_root == nil or project_root == vim.fn.expand('$HOME') then
    return nil
  end

  if M.is_files_found(project_root, M.ft.node_files) then
    return project_root
  end

  -- Node.js関連のファイルが見つからない場合はnilを返す
  return nil
end

function M.has_root_marker(root_markers)
  local root_dir = vim.fn.getcwd()
  for _, marker in ipairs(root_markers) do
    if vim.fn.filereadable(root_dir .. '/' .. marker) == 1 then
      return true
    end
  end
  return false
end

M.capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

return M
