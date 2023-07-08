#!bin/sh

# ----
# dotfilesのシンボリックリンクを作成する
# 引数：なし
# 戻値：なし
# 備考：
# ----

SCRIPT_DIR_PATH=$(cd $(dirname $0);pwd)

# dotfilesのシンボリックリンク作成
mkdir ~/.config
ln -fns ${SCRIPT_DIR_PATH}/.config/nvim ~/.config/nvim
ln -fns ${SCRIPT_DIR_PATH}/.bash_profile ~/.bash_profile
ln -fns ${SCRIPT_DIR_PATH}/.bashrc ~/.bashrc

source ~/.bash_profile


if [ "$(uname)" == 'Darwin' ]; then
  # Homebrewをインストールする
  # ref: https://docs.brew.sh/Installation
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

  source ~/.bash_profile

  # Homebrewで管理しているパッケージをインストールする
  # ref: https://tech.gootablog.com/article/homebrew-brewfile/
  brew bundle

  source ~/.bash_profile
fi
