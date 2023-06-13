return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    { 'f3fora/cmp-spell' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-cmdline' },
    { 'hrsh7th/cmp-nvim-lsp', dependencies = { 'neovim/nvim-lspconfig' } },
    { 'hrsh7th/cmp-nvim-lua' },
    { 'hrsh7th/cmp-path' },
    { 'kdheepak/cmp-latex-symbols' },
    { 'lukas-reineke/cmp-under-comparator' },
    { 'onsails/lspkind.nvim' },
    { 'ray-x/cmp-treesitter' },
  },
  config = function()
    -- Lspkindのrequire
    local lspkind = require('lspkind')
    --補完関係の設定
    local cmp = require('cmp')

    cmp.setup({
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      sources = {
        { name = "buffer" },
        { name = "nvim_lsp" },
        { name = "path" },
        { name = 'buffer' },
        { name = 'latex_symbols' },
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'nvim_lua' },
        { name = 'path' },
        { name = 'spell' },
        { name = 'treesitter' },
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(), --補完欄を一つ上に移動
        ['<C-n>'] = cmp.mapping.select_next_item(), --補完欄を一つ下に移動
        ['<C-u>'] = cmp.mapping.scroll_docs(-5), -- docsを上にスクロール
        ['<C-d>'] = cmp.mapping.scroll_docs(5), -- docsを下にスクロール
        ['<C-e>'] = cmp.mapping.abort(), -- 補完候補を閉じる(補完しない)
        ['<Tab>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true
        }),--Tabで補完を選択確定
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true
        }),--Returnで補完を選択確定
      }),
      experimental = {
        ghost_text = false,
      },
      -- Lspkind(アイコン)を設定
      formatting = {
        format = lspkind.cmp_format({
          mode = 'symbol', -- show only symbol annotations
          maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
          ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
          -- The function below will be called before any actual modifications from lspkind
          -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
        })
      }
    })
    cmp.setup.cmdline('/', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' } --ソース類を設定
      }
    })
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'path' }, --ソース類を設定
      },
    })

  end
}
