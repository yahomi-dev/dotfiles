-- ref: https://github.com/hrsh7th/nvim-cmp/wiki/Language-Server-Specific-Samples
--    : https://github.com/hrsh7th/dotfiles/blob/477047a6280c2c1f858e94e9073fd20bab05c0c7/.config/nvim/init.vim#L767-L852
--    : https://github.com/hrsh7th/nvim-cmp/blob/f51dc68e1bb170fc49c2d7e13eb45e5ec83f5ee9/lua/cmp/config/mapping.lua
--    : https://zenn.dev/botamotch/articles/21073d78bc68bf

local cmp = require('cmp')
local cmp_types = require('cmp.types')
local lspkind = require('lspkind')
local luasnip = require('luasnip')
-- local icons = require('plugins.config.shared.icons')

cmp.setup {
  completion = {
    keyword_length = 2,
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  sources = {
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'luasnip' },
    { name = 'path' },
    { name = 'ghq' },
    { name = 'latex_symbol' },
    { name = 'emoji' },
    { name = 'dynamic' },
    { name = 'calc' },
    { name = 'buffer' },
    { name = 'dictionary', keyword_length = 2 },
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-p>'] = cmp.mapping.select_prev_item(), --補完欄を一つ上に移動
    ['<C-n>'] = cmp.mapping.select_next_item(), --補完欄を一つ下に移動
    ['<C-u>'] = cmp.mapping.scroll_docs(-5), -- docsを上にスクロール
    ['<C-d>'] = cmp.mapping.scroll_docs(5), -- docsを下にスクロール
    ['<C-e>'] = cmp.mapping.abort(), -- 補完候補を閉じる(補完しない)
    --
    --Tabで補完を選択確定
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if luasnip.locally_jumpable(1) then
          luasnip.jump(1)
        else
          cmp.confirm {
            select = true,
          }
        end
      else
        fallback()
      end
    end, { 'i', 's' }),

    -- LuaSnip設定
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        end
      else
        fallback()
      end
    end, { 'i', 's' }),

    -- Returnで補完を選択確定
    ['<CR>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if luasnip.expandable() then
          luasnip.expand()
        else
          cmp.confirm {
            select = true,
          }
        end
      else
        fallback()
      end
    end),
  },

  experimental = {
    ghost_text = false,
  },
  formatting = {
    -- ref: https://github.com/onsails/lspkind.nvim/pull/30
    fields = {
      cmp.ItemField.Kind,
      cmp.ItemField.Abbr,
      cmp.ItemField.Menu,
    },
    format = lspkind.cmp_format {
      mode = 'symbol',
      maxwidth = 50,
      ellipsis_char = '…',
      menu = {
        buffer = 'buffer',
        calc = 'calc',
        cmdline = 'cmdline',
        dictionary = 'dictionary',
        dynamic = 'dynamic',
        emoji = 'emoji',
        ghq = 'ghq',
        latex_symbol = 'latex',
        nvim_lsp = 'lsp',
        nvim_lua = 'lua',
        nvim_lsp_signature_help = 'signature',
        path = 'path',
        treesitter = 'treesitter',
      },
      -- symbol_map = {
      --   Text = icons.text,
      --   Method = icons.method,
      --   Function = icons.func,
      --   Constructor = icons.constructor,
      --   Field = icons.field,
      --   Variable = icons.variable,
      --   Class = icons.class,
      --   Interface = icons.interface,
      --   Module = icons.module,
      --   Property = icons.property,
      --   Unit = icons.unit,
      --   Value = icons.value,
      --   Enum = icons.enum,
      --   Keyword = icons.keyword,
      --   Snippet = icons.snippet,
      --   Color = icons.color,
      --   File = icons.file,
      --   Reference = icons.reference,
      --   Folder = icons.folder,
      --   EnumMember = icons.enum_member,
      --   Constant = icons.constant,
      --   Struct = icons.struct,
      --   Event = icons.event,
      --   Operator = icons.operator,
      --   TypeParameter = icons.type_parameter,
      -- },
    },
    before = function(entry, vim_item)
      local word = entry:get_insert_text()
      if entry.completion_item.insertTextFormat == cmp_types.lsp.InsertTextFormat.Snippet then
        word = vim.lsp.util.parse_snippet(word)
      end
      word = word:gsub('\n', '')
      if entry.completion_item.insertTextFormat == cmp_types.lsp.InsertTextFormat.Snippet then
        word = word .. '…'
      end
      vim_item.abbr = word
      return vim_item
    end,
  },
}

cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' },
    { name = 'dictionary', keyword_length = 3 },
  },
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'path' },
    { name = 'cmdline' },
    { name = 'dictionary', keyword_length = 3 },
  },
})
