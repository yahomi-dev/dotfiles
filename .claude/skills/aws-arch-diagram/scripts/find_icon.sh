#!/usr/bin/env bash
# AWS 公式 Icon package (SVG) からキーワードでアイコンを探す。
# usage: find_icon.sh <keyword> [keyword ...]   例: find_icon.sh lambda / find_icon.sh "api-gateway" endpoint
# 保存先: AWS_ICONS_DIR (既定は ${XDG_CACHE_HOME:-~/.cache}/aws-architecture-icons) の下の Icon-package_<版>/ (Architecture-Service-Icons = サービス、Resource-Icons = リソース、Architecture-Group-Icons = グループ枠)
# 無ければ scripts/fetch_icons.sh で取得する
set -u

root="${AWS_ICONS_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/aws-architecture-icons}"

if [ ! -d "$root" ]; then
  echo "公式パッケージが $root に無い。scripts/fetch_icons.sh で取得する (保存先は AWS_ICONS_DIR で変えられる)" >&2
  exit 1
fi

for kw in "$@"; do
  find "$root" -type f -name "*.svg" -iname "*${kw}*" | sed "s|^$root/||" | sort
done
