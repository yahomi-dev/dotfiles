#!/bin/sh
# src/ の part から、領域ごとの図と全体図の mmd を組み立てる (1-overview.mmd と 7-legend.mmd は直接書く)。part を変更したら再実行する
# 削除したもの (_removed-*.part) は色付きの図 (2〜6) にだけ混ぜ、最終版 (8-all-final) には混ぜない。既存の実体に残した削除した属性の行は strip-removed.mjs が落とす
# MODEL_DIFF_DIAGRAM_DIR: model-diff-diagram スキルのディレクトリ (既定は ~/.claude/skills/model-diff-diagram)
set -eu
S=${MODEL_DIFF_DIAGRAM_DIR:-$HOME/.claude/skills/model-diff-diagram}
cd "$(dirname "$0")/src"

# 別の図で定義した実体を、関係を示すためだけに置く (注記は物理の表名)
ref() {
  for n in "$@"; do
    case $n in
      顧客) p=customers ;;
      商品) p=products ;;
      注文) p=orders ;;
      *) echo "ref: 対応表に無い実体: $n" >&2; exit 1 ;;
    esac
    printf '    class %s {\n        <<%s>>\n    }\n' "$n" "$p"
  done
}

{ echo classDiagram; cat _customers.part _rel-customers.part; } > 2-customers.mmd
{ echo classDiagram; cat _catalog.part _rel-catalog.part; } > 3-catalog.mmd
{ echo classDiagram; ref 顧客 商品; cat _orders.part _removed-orders.part _rel-orders.part _removed-rel-orders.part; } > 4-orders.mmd
{ echo classDiagram; cat _customers.part _catalog.part _orders.part _removed-orders.part _rel-*.part _removed-rel-*.part; } > 5-all.mmd
{ echo classDiagram; cat _rel-*.part _removed-rel-*.part; } > 6-all-relations.mmd
{ echo classDiagram; cat _customers.part _catalog.part _orders.part _rel-*.part; } | node "$S/scripts/strip-removed.mjs" changes.json > 8-all-final.mmd
echo "組み立てた: 2-customers 3-catalog 4-orders 5-all 6-all-relations 8-all-final"
