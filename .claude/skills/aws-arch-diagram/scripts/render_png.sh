#!/usr/bin/env bash
# export/ 配下の standalone HTML を headless Chromium で 2 倍解像度の PNG にする。
# usage: render_png.sh <export_dir> [name ...]   (name 省略時は *.html 全部)
# 前提: playwright が取得した Chromium (~/.cache/ms-playwright/chromium-*/) か、CHROME 環境変数でパス指定
set -u

dir="${1:?export dir}"
shift || true

if [ -z "${CHROME:-}" ]; then
  CHROME="$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux*/chrome 2>/dev/null | sort -V | tail -1)"
fi

if [ -z "$CHROME" ] || [ ! -x "$CHROME" ]; then
  echo "Chromium が見つからない。CHROME=/path/to/chrome を指定する" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  set -- $(cd "$dir" && ls *.html | sed 's/\.html$//')
fi

for name in "$@"; do
  # .size は "w h" 1 行。末尾改行が無いと read が非 0 を返すので && で繋がない
  read -r w h < "$dir/$name.size" || true
  "$CHROME" --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=2 --virtual-time-budget=10000 \
    --window-size="$w,$h" --screenshot="$dir/$name.png" "file://$(cd "$dir" && pwd)/$name.html" >/dev/null 2>&1
  echo "$name.png ($((w * 2))x$((h * 2)))"
done
