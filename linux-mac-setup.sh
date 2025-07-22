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
echo "シンボリックリンクが作成されました！"
