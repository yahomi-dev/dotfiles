#!/bin/bash

# Dotfiles ディレクトリへのパス
DOTFILES_DIR="$HOME/dotfiles"

# Windows用のシンボリックリンク作成 (PowerShell)
echo "Windows用のシンボリックリンクを作成します。"
pwsh -Command "New-Item -ItemType SymbolicLink -Path \$HOME\.config\nvim -Target \$HOME\dotfiles\.config\nvim"
pwsh -Command "New-Item -ItemType SymbolicLink -Path \$HOME\.zshrc -Target \$HOME\dotfiles\.zshrc"

echo "Windows用のシンボリックリンクが作成されました！"
