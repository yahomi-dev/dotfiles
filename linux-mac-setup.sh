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

# 既存のファイルやディレクトリを壊さずに symlink を張る (実体があるときは警告して飛ばす)
link() {
  src="$1"
  dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "SKIP: $dst は実体があります。中身を確認して退避してから再実行してください"
    return 0
  fi
  ln -sfn "$src" "$dst"
}

# Claude Code の設定 (既存の ~/.claude/ を壊さず、管理対象だけ symlink)
mkdir -p "$HOME/.claude"
for f in CLAUDE.md settings.json statusline.mjs statusline-v2.mjs; do
  link "$DOTFILES_DIR/.claude/$f" "$HOME/.claude/$f"
done
for d in rules skills agents commands hooks scripts; do
  link "$DOTFILES_DIR/.claude/$d" "$HOME/.claude/$d"
done

# 仕事用のプロファイル (CLAUDE_CONFIG_DIR=~/.claude-work、.zshrc の work-claude で起動)
# CLAUDE.md と rules は通常のプロファイルと共通にする
mkdir -p "$HOME/.claude-work"
for f in settings.json hooks skills; do
  link "$DOTFILES_DIR/.claude-work/$f" "$HOME/.claude-work/$f"
done
link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude-work/CLAUDE.md"
link "$DOTFILES_DIR/.claude/rules" "$HOME/.claude-work/rules"

# 社内向けのスキルは別のリポジトリ (dot-claude-work) で管理する。clone していなければ飛ばす
# skills/ の中に張る symlink は .gitignore の対象なので、このリポジトリには入らない
WORK_SKILLS_DIR="${WORK_SKILLS_DIR:-$HOME/dev/dot-claude-work/skills}"
if [ -d "$WORK_SKILLS_DIR" ]; then
  for s in "$WORK_SKILLS_DIR"/*/; do
    [ -d "$s" ] || continue
    s="${s%/}"
    link "$s" "$DOTFILES_DIR/.claude/skills/$(basename "$s")"
  done
fi

find "$DOTFILES_DIR/.claude/hooks" "$DOTFILES_DIR/.claude/scripts" "$DOTFILES_DIR/.claude-work/hooks" \
  -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +

# rules と skills の一部は ~/ghq の coding-style リポへの相対 symlink
if [ ! -d "$HOME/ghq/github.com/yahomi-dev/coding-style" ]; then
  echo "NOTE: coding-style が未取得のため一部のルールとスキルがリンク切れです -> ghq get https://github.com/yahomi-dev/coding-style.git"
fi

# MCP サーバ (ユーザのスコープ)。認証が要る社内のサーバは各サービスの手順で追加する
if command -v claude > /dev/null 2>&1; then
  claude mcp get context7 > /dev/null 2>&1 || claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
fi

# git の global ignore。core.excludesFile を設定すると ~/.config/git/ignore は読まれなくなるので、無視の設定は .gitignore_global に集める
ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesFile "$HOME/.gitignore_global"

# worktree-helper を ~/bin に配置
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/worktree-helper" "$HOME/bin/worktree-helper"

echo "シンボリックリンクが作成されました！"
