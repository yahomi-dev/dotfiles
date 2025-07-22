#!/bin/bash

# OSの判定
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  echo "LinuxまたはmacOSが検出されました。"

  # Linux/macOS用スクリプトを実行
  bash ./linux-mac-setup.sh

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  echo "Windowsが検出されました。"

  # Windows用スクリプトを実行
  bash ./windows-setup.sh

else
  echo "サポートされていないOSです。"
  exit 1
fi
