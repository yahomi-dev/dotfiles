#!/bin/sh
# ディレクトリの中の mmd (erDiagram、凡例や全体の flowchart も可) をすべて同名の SVG に描く。描く前に setup-tool.sh で道具を用意し、手当てを当てる。
# usage: sh render.sh <mmd のディレクトリ> [--wide <名前>,<名前>...] [--sha256]
#   --wide    指定した図 (拡張子なしの名前) は箱と層の間隔を広げて描く (--node-spacing 100 --layer-spacing 200。erDiagram の既定は 70 / 90)。全部の表を 1 枚に描く図に使う
#   --sha256  描いた mmd と SVG の SHA-256 を <ディレクトリ>/rendered.sha256 に書く (CI で描けないとき、この記録と今のファイルを比べる検査に使う)
# テーマは github-light。道具の保存先は setup-tool.sh と同じ PRETTY_MERMAID_DIR
set -eu

S=$(cd "$(dirname "$0")" && pwd)
dir=${1:?usage: sh render.sh <mmd のディレクトリ> [--wide <名前>,...] [--sha256]}
shift
wide=""
record=0

while [ $# -gt 0 ]; do
  case "$1" in
    --wide) wide=${2:?--wide には名前を渡す}; shift 2 ;;
    --sha256) record=1; shift ;;
    *) echo "知らない引数: $1" >&2; exit 2 ;;
  esac
done

sh "$S/setup-tool.sh"
TOOL_DIR=${PRETTY_MERMAID_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pretty-mermaid}
cd "$dir"

for mmd in *.mmd; do
  name=${mmd%.mmd}
  case ",$wide," in
    *",$name,"*) spacing="--node-spacing 100 --layer-spacing 200" ;;
    *) spacing="" ;;
  esac
  # shellcheck disable=SC2086 # spacing は空か複数の引数
  node "$TOOL_DIR/scripts/render.mjs" --input "$mmd" --output "$name.svg" --theme github-light $spacing
done

if [ "$record" = 1 ]; then
  sha256sum *.mmd *.svg > rendered.sha256
fi
