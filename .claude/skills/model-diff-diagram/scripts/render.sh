#!/bin/sh
# 作業ディレクトリの src/<番号>-<名前>.mmd をすべて SVG に描き、src/changes.json の差分に色を付ける。--png を付けると確認用の PNG (幅 1600) も作る
# usage: sh render.sh [<作業ディレクトリ>] [--png]   (作業ディレクトリの既定はカレントディレクトリ)
# 出力: <作業ディレクトリ>/<番号>-<名前>.svg (と .png)。名前が -final で終わる図 (色なし、削除したものなしの最終版) には色を付けない
# 道具の用意と手当ては setup-tool.sh (保存先は PRETTY_MERMAID_DIR)
set -eu

S=$(cd "$(dirname "$0")" && pwd)
dir=.
png=0

for arg in "$@"; do
  case "$arg" in
    --png) png=1 ;;
    -*) echo "知らない引数: $arg" >&2; exit 2 ;;
    *) dir=$arg ;;
  esac
done

sh "$S/setup-tool.sh"
T=${PRETTY_MERMAID_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pretty-mermaid-model-diff}
cd "$dir"

# 色はテーマを使わず直接指定する (テーマと併用すると --line が負ける)。線は #57606a
C="--bg #ffffff --fg #1f2328 --line #57606a --accent #57606a --muted #24292f --border #8c959f"
svgs=""
marks=""

for f in src/[0-9]*-*.mmd; do
  b=$(basename "$f" .mmd)
  # shellcheck disable=SC2086 # C は複数の引数
  node "$T/scripts/render.mjs" --input "$f" --output "$b.svg" $C
  svgs="$svgs $b.svg"
  case "$b" in
    *-final) ;;
    *) marks="$marks $b.svg" ;;
  esac
done

# 差分の色 (src/changes.json) を SVG に塗る。エンジンの classDiagram は style / classDef を読まないので描いた後に書き換える
# shellcheck disable=SC2086 # marks は複数のファイル
node "$S/mark-changes.mjs" src/changes.json $marks

# PNG は色を塗った後の SVG から作る (render.mjs に mmd から作らせると色が付かない)
if [ "$png" = 1 ]; then
  # shellcheck disable=SC2086 # svgs は複数のファイル
  node --input-type=module - "$T" $svgs <<'JS'
import { readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
const [tool, ...svgs] = process.argv.slice(2);
const { renderSvgToPng } = await import(pathToFileURL(`${tool}/scripts/png.mjs`).href);
for (const svg of svgs) {
  const png = svg.replace(/\.svg$/, ".png");
  writeFileSync(png, renderSvgToPng(readFileSync(svg, "utf8"), 1600));
  console.log(`PNG diagram saved to ${png}`);
}
JS
fi
