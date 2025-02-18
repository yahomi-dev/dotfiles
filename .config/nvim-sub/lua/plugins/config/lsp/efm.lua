-- efm-langserverの設定セットを作ってる人がいるので、参考にすると良い
-- https://github.com/creativenull/efmls-configs-nvim/tree/main/lua/efmls-configs

local stylua = {
  prefix = 'stylua',
  formatCommand = 'stylua -',
    formatStdin = true,
  rootMarkers = { 'stylua.toml', '.stylua.toml' },
}

local eslint_d = {
  lintCommand = 'eslint_d -f unix --stdin --stdin-filename ${INPUT}',
  lintStdin = true,
  lintFormats = { '%f:%l:%c: %m' },
  lintIgnoreExitCode = true,
  rootMarkers = { '.eslintrc.js' },
}

local biome = {
  formatCommand = 'biome format --stdin-filepath ${INPUT}',
  formatStdin = true,
  lintCommand = 'biome check --stdin-filepath ${INPUT}',
  lintStdin = true,
  lintFormats = { '%f:%l:%c: %m' },
  rootMarkers = { '.biomerc.json' },
}

local languages = {
  lua = { stylua },
  javascript = { eslint_d, biome },
  javascriptreact = { eslint_d, biome },
  typescript = { eslint_d, biome },
  typescriptreact = { eslint_d, biome },
}

return {
  init_options = {
    documentFormatting = true,
    documentRangeFormatting = true,
    codeAction = true,
  },
  settings = {
    languages = languages,
  },
}
