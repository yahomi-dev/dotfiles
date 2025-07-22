local M = {}

---@return number @UserLspConfig augroup ID
M.lsp_group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true })

return M
