-- プロジェクトごとのフォーマッター設定
-- キー: プロジェクトの絶対パス（末尾スラッシュなし）
--
-- 例:
--   フォーマット無効:
--     [vim.fn.expand('~/work/legacy')] = { enabled = false },
--
--   フォーマッターを上書き:
--     [vim.fn.expand('~/work/prettier-proj')] = {
--       enabled = true,
--       formatters_by_ft = {
--         typescript = { 'prettier' },
--         json       = { 'prettier' },
--       },
--     },
--
-- エントリがないプロジェクトはデフォルト設定を使用

return {
  [vim.fn.expand('.config/nvim-pack/lua/config')] = {
    enabled = false,
    formatters_by_ft = {
      lua = { 'styLua' },
    },
  },
}
