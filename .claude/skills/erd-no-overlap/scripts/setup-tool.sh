#!/bin/sh
# 描画の道具 beautiful-mermaid (ブラウザ不要の Mermaid 描画。imxv/Pretty-mermaid-skills の scripts/render.mjs) を固定の版で用意し、dist に手当て 6 点 (等幅の文字幅 1 点 + erDiagram の配置 5 点) を当てる。
# usage: sh setup-tool.sh   (render.sh が毎回呼ぶ。何度実行しても手当ては 1 回だけ効く)
# 保存先: PRETTY_MERMAID_DIR (既定は ${XDG_CACHE_HOME:-~/.cache}/pretty-mermaid)。無ければ取得して依存を入れる (git、node と npm、ネットワークが要る)
# 取得元: https://github.com/imxv/Pretty-mermaid-skills 。版は TOOL_REVISION のコミットで固定する (このコミットの package-lock.json で beautiful-mermaid 1.1.3)
# classDiagram 用の手当て (model-diff-diagram スキル) は等幅の文字幅を除いて別の箇所なので、同じ保存先に両方を当ててもよい (どちらを先に当ててもよい)
set -eu

TOOL_DIR=${PRETTY_MERMAID_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pretty-mermaid}
TOOL_REVISION=e234ab73c2992f03c36db04fd55ebb90abca9c45
DIST="$TOOL_DIR/node_modules/beautiful-mermaid/dist/index.js"

if [ ! -d "$TOOL_DIR" ]; then
  git clone --quiet https://github.com/imxv/Pretty-mermaid-skills "$TOOL_DIR"
  git -C "$TOOL_DIR" checkout --quiet "$TOOL_REVISION"
fi

if [ ! -f "$DIST" ]; then
  (cd "$TOOL_DIR" && npm ci --no-audit --no-fund)
fi

rev=$(git -C "$TOOL_DIR" rev-parse HEAD 2>/dev/null || echo unknown)

if [ "$rev" != "$TOOL_REVISION" ]; then
  echo "注意: $TOOL_DIR の版は $rev (固定の版は $TOOL_REVISION)。手当てが当たらなければ止まる" >&2
fi

node - "$DIST" <<'JS'
const fs = require("fs");
const path = process.argv[2];
const patches = [
  {
    // 等幅の文字幅の見積もりは「文字数 x 0.6em」の固定計算で、日本語 (1 文字 1em) の列名が箱からはみ出る。全角と絵文字を 1.05em に数える
    // erDiagram の列と classDiagram の属性の両方が使う箇所なので、model-diff-diagram スキルの setup-tool.sh も同じ手当てを当てる (当て済みなら何もしない)
    name: "等幅の文字幅 (全角 1.05em)",
    before: "function estimateMonoTextWidth(text, fontSize) {\n  return text.length * fontSize * 0.6;\n}",
    after: "function estimateMonoTextWidth(text, fontSize) {\n  let units = 0;\n  for (const ch of text) {\n    const code = ch.codePointAt(0);\n    units += code !== void 0 && (isFullwidth(code) || isEmoji(ch)) ? 1.05 : 0.6;\n  }\n  return units * fontSize;\n}",
  },
  {
    // erDiagram の箱と層の間隔は固定値 (70 / 90) で、--node-spacing と --layer-spacing が効かない。引数が固定値より大きければ引数を使う
    name: "ER の箱と層の間隔 (引数)",
    before: "      \"elk.spacing.nodeNode\": String(ER.nodeSpacing),\n      \"elk.layered.spacing.nodeNodeBetweenLayers\": String(ER.layerSpacing),",
    after: "      \"elk.spacing.nodeNode\": String(Math.max(ER.nodeSpacing, _options.nodeSpacing ?? 0)),\n      \"elk.layered.spacing.nodeNodeBetweenLayers\": String(Math.max(ER.layerSpacing, _options.layerSpacing ?? 0)),",
  },
  {
    // 線同士、線と箱、線とラベルの間隔が既定のままで、線の文言が別の線に重なる。間隔を広げる
    name: "ER の線とラベルの間隔",
    before: "      \"elk.padding\": `[top=${ER.padding},left=${ER.padding},bottom=${ER.padding},right=${ER.padding}]`,\n      \"elk.edgeRouting\": \"ORTHOGONAL\",\n      \"elk.edgeLabels.placement\": \"CENTER\"\n    },",
    after: "      \"elk.padding\": `[top=${ER.padding},left=${ER.padding},bottom=${ER.padding},right=${ER.padding}]`,\n      \"elk.edgeRouting\": \"ORTHOGONAL\",\n      \"elk.edgeLabels.placement\": \"CENTER\",\n      \"elk.layered.spacing.edgeNodeBetweenLayers\": \"40\",\n      \"elk.layered.spacing.edgeEdgeBetweenLayers\": \"24\",\n      \"elk.spacing.edgeNode\": \"32\",\n      \"elk.spacing.edgeEdge\": \"20\",\n      \"elk.spacing.edgeLabel\": \"12\"\n    },",
  },
  {
    // ELK は線の文言の位置を他の線と重ならないように決めるが、道具はそれを捨てて線の経路の中点に描く。ELK の位置を残す
    name: "ER のラベルの位置 (ELK の結果を残す)",
    before: "      label: rel.label,\n      identifying: rel.identifying,\n      points\n    });",
    after: "      label: rel.label,\n      identifying: rel.identifying,\n      points,\n      labelPosition: elkEdge.labels?.[0]?.x != null && elkEdge.labels[0].y != null ? { x: elkEdge.labels[0].x + (elkEdge.labels[0].width ?? 0) / 2, y: elkEdge.labels[0].y + (elkEdge.labels[0].height ?? 0) / 2 } : void 0\n    });",
  },
  {
    // 線の文言は線の横に置かれ、平行な 2 本の間ではどちらの線のものか読めない。線の上に載せる (文言の背景が線を切る)
    name: "ER のラベルを線の上に",
    before: "    const edge = { id: `e${i}`, sources: [rel.entity1], targets: [rel.entity2] };\n    if (rel.label) {\n      edge.labels = [{ text: rel.label, width: metrics.width + 8, height: metrics.height + 6 }];",
    after: "    const edge = { id: `e${i}`, sources: [rel.entity1], targets: [rel.entity2] };\n    if (rel.label) {\n      edge.labels = [{ text: rel.label, width: metrics.width + 8, height: metrics.height + 6, layoutOptions: { \"elk.edgeLabels.inline\": \"true\" } }];",
  },
  {
    // 残した位置に描く (無ければ今までどおり経路の中点)
    name: "ER のラベルの位置 (描く)",
    before: "  const mid = midpoint2(rel.points);",
    after: "  const mid = rel.labelPosition ?? midpoint2(rel.points);",
  },
];
const patched = patches.reduce((source, { name, before, after }) => {
  if (source.includes(after)) {
    console.log(`beautiful-mermaid: ${name} は修正済み`);
    return source;
  }
  if (source.includes(before)) {
    console.log(`beautiful-mermaid: ${name} を修正した`);
    return source.replace(before, after);
  }
  console.error(`beautiful-mermaid の ${name} の箇所が見つからない (版が変わった?)。手当てを見直す`);
  process.exit(1);
}, fs.readFileSync(path, "utf8"));
fs.writeFileSync(path, patched);
JS
