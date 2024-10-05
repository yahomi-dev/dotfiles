#!/bin/bash

# OSの判定
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  # Linux or macOS
  echo "LinuxまたはmacOSが検出されました。シンボリックリンクを削除します。"

  # シンボリックリンクの削除
  rm -f "$HOME/.config/nvim"
  rm -f "$HOME/.zshrc"

  echo "シンボリックリンクが削除されました！"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  # Windows
  echo "Windowsが検出されました。でシンボリックリンクを削除します。"

  # PowerShellを使ってシンボリックリンクを削除
  pwsh -Command "Remove-Item -Path \$HOME\.config\nvim -Force"
  pwsh -Command "Remove-Item -Path \$HOME\.zshrc -Force"

  echo "Windows用のシンボリックリンクが削除されました！"

else
  echo "サポートされていないOSです。"
  exit 1
fi
