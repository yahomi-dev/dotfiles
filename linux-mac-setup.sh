#!/bin/bash

# Dotfiles ディレクトリへのパス
DOTFILES_DIR="$HOME/dotfiles"

# Homebrewのインストール
if ! command -v brew &> /dev/null; then
  echo "Homebrewがインストールされていません。インストールを開始します。"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrewはすでにインストールされています。"
fi

# Brewfileを使ったツールのインストール
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
  echo "Brewfileを使ってツールをインストールします。"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
else
  echo "Brewfileが見つかりませんでした。"
fi

# シンボリックリンクの作成
ln -sf "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"

# Claude Code の設定（既存 ~/.claude/ を壊さず、管理対象だけ symlink）
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$DOTFILES_DIR/.claude/rules" "$HOME/.claude/rules"
ln -sfn "$DOTFILES_DIR/.claude/skills" "$HOME/.claude/skills"
ln -sfn "$DOTFILES_DIR/.claude/agents" "$HOME/.claude/agents"
ln -sfn "$DOTFILES_DIR/.claude/commands" "$HOME/.claude/commands"
ln -sf "$DOTFILES_DIR/.claude/statusline.mjs" "$HOME/.claude/statusline.mjs"

# rules 内の typescript/react/design-policy は ~/ghq の coding-style リポへの相対 symlink
if [ ! -d "$HOME/ghq/github.com/yahomi-dev/coding-style" ]; then
  echo "NOTE: coding-style が未取得のため一部ルールがリンク切れです -> ghq get https://github.com/yahomi-dev/coding-style.git"
fi
ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesFile "$HOME/.gitignore_global"

# worktree-helper を ~/bin に配置
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/worktree-helper" "$HOME/bin/worktree-helper"

echo "シンボリックリンクが作成されました！"
