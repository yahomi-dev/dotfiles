# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Neovim configuration repository using Lua. The configuration supports both regular Neovim and VS Code Neovim extension with separate configurations.

## Key Architecture

### Entry Points
- `init.lua` - Main entry point that detects environment (VS Code vs regular Neovim) and loads appropriate configuration
- `vscode_config/init.lua` - Simplified configuration for VS Code Neovim extension

### Configuration Structure
```
lua/
├── config/          # Core Neovim settings
│   ├── options.lua  # Editor settings
│   ├── keymaps.lua  # Key mappings (leader = Space)
│   ├── lazy.lua     # Plugin manager setup
│   └── autocmd.lua  # Autocommands
├── plugins/         # Plugin specifications and configs
│   ├── init.lua     # Plugin list (40+ plugins)
│   └── config/      # Individual plugin configurations
│       ├── lsp/     # LSP server configurations
│       ├── color-theme/  # Color scheme configs
│       └── shared/  # Reusable components
└── util/           # Utility modules
```

### Plugin Management
- Uses **lazy.nvim** as plugin manager
- Plugin lock file: `lazy-lock.json`
- Auto-bootstraps on first run

## Development Commands

### Code Formatting
- **Format current file**: `:Format` command (supports range selection)
- **Lua formatting**: Configured with StyLua (`.stylua.toml` present)
  - Style: Tabs, width 2, 120 column width, prefer single quotes
- **Formatters by filetype**:
  - Lua: stylua
  - Python: isort, black
  - JavaScript/TypeScript: biome, prettierd, prettier (first available)
  - PHP: pint, php_cs_fixer (first available)
  - C++: clang-format

### LSP Management
- **Install LSP servers**: Through Mason UI (`:Mason`)
- **Check LSP status**: `:LspInfo`
- **Format on save**: Configured via conform.nvim

## Key Components

### LSP Setup
- Mason.nvim for LSP server installation
- nvim-lspconfig for server configuration
- conform.nvim for formatting (recently migrated from EFM)
- Custom attach function in `lua/plugins/config/lsp/attach.lua`

### Plugin Categories
- **Completion**: nvim-cmp with multiple sources
- **File Navigation**: Telescope, Fern
- **Git Integration**: gitsigns, vim-gin
- **Syntax**: Tree-sitter with auto-install
- **AI Integration**: claude-code.nvim (recently added)

### Platform-Specific Features
- WSL clipboard integration
- macOS input method switching on insert leave
- VS Code detection for minimal config loading

## Recent Changes
- Migrated from EFM to conform.nvim for formatting
- Added claude-code.nvim plugin integration
- Updated LSP configuration structure