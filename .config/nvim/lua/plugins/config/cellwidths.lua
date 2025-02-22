require('cellwidths').setup {
  name = 'user/custom',
  ---@param cw cellwidths
  fallback = function(cw)
    cw.load('default')

    cw.add {
      { 0x2100, 0x214d, 2 }, -- 記号や特殊な文字(™℗©℠⅀)
      { 0x203B, 0x203B, 2 }, -- ※
    }
  end,
}
