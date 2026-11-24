#!/bin/sh
# 描画の道具 beautiful-mermaid (ブラウザ不要の Mermaid 描画。imxv/Pretty-mermaid-skills の scripts/render.mjs) を固定の版で用意し、classDiagram の箱の幅と間隔の手当て 4 点を dist に当てる。
# usage: sh setup-tool.sh   (render.sh が毎回呼ぶ。何度実行しても手当ては 1 回だけ効く)
# 保存先: PRETTY_MERMAID_DIR (既定は ${XDG_CACHE_HOME:-~/.cache}/pretty-mermaid-model-diff)。無ければ取得して依存を入れる (git、node と npm、ネットワークが要る)
# 取得元: https://github.com/imxv/Pretty-mermaid-skills 。版は TOOL_REVISION のコミットで固定する (このコミットの package-lock.json で beautiful-mermaid 1.1.3)
# 既定の保存先を erd-no-overlap スキル (~/.cache/pretty-mermaid) と分けているのは、別の手当て (下の「当てていない手当て」) を当てた dist で描くと図の配置が変わるため
set -eu

TOOL_DIR=${PRETTY_MERMAID_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pretty-mermaid-model-diff}
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

# 当てていない手当て: ELK の線の間隔を広げる手当て (elk.layered.spacing.edgeNodeBetweenLayers 48、edgeEdgeBetweenLayers 28、elk.spacing.edgeNode 36、edgeEdge 24、edgeLabel 14)。
# 元のスクリプトは当て済みの判定に元の dist にもある文字列を使っていたため、この手当ては一度も当たっていなかった。今の図はこの手当てなしの配置なので、出力を変えないために当てない
node - "$DIST" <<'JS'
const fs = require("fs");
const p = process.argv[2];
const patches = [
  {
    // 属性の幅は「文字数 x 0.6em」の固定計算で、日本語 (1 文字 1em) が枠からはみ出る。全角と絵文字を 1.05em に数える
    // erDiagram の列と共有の箇所なので、erd-no-overlap スキルの setup-tool.sh も同じ手当てを当てる (当て済みなら何もしない)
    name: "属性の幅 (全角 1.05em)",
    before: "function estimateMonoTextWidth(text, fontSize) {\n  return text.length * fontSize * 0.6;\n}",
    after: "function estimateMonoTextWidth(text, fontSize) {\n  let units = 0;\n  for (const ch of text) {\n    const code = ch.codePointAt(0);\n    units += code !== void 0 && (isFullwidth(code) || isEmoji(ch)) ? 1.05 : 0.6;\n  }\n  return units * fontSize;\n}",
  },
  {
    // 箱の幅に <<注記>> の幅が入っておらず、長い表名が枠からはみ出る。注記の幅も入れる
    name: "注記の幅",
    skipIf: "const annotationW = cls.annotation",
    before: "    const width = Math.max(CLS.minWidth, headerTextW + CLS.boxPadX * 2, maxAttrW + CLS.boxPadX * 2, maxMethodW + CLS.boxPadX * 2);",
    after: "    const annotationW = cls.annotation ? estimateTextWidth(`<<${cls.annotation}>>`, 10, 500) : 0;\n    const width = Math.max(CLS.minWidth, headerTextW + CLS.boxPadX * 2, annotationW + CLS.boxPadX * 2, maxAttrW + CLS.boxPadX * 2, maxMethodW + CLS.boxPadX * 2);",
  },
  {
    // 線が多く出る実体は、線の数に応じて箱を広げる。狭いと線の端と多重度のラベルが重なる
    name: "線の数で箱を広げる",
    skipIf: "const degree = diagram.relationships",
    before: "    const width = Math.max(CLS.minWidth, headerTextW + CLS.boxPadX * 2, annotationW + CLS.boxPadX * 2, maxAttrW + CLS.boxPadX * 2, maxMethodW + CLS.boxPadX * 2);",
    after: "    const degree = diagram.relationships.filter((r) => r.from === cls.id || r.to === cls.id).length;\n    const width = Math.max(CLS.minWidth, headerTextW + CLS.boxPadX * 2, annotationW + CLS.boxPadX * 2, maxAttrW + CLS.boxPadX * 2, maxMethodW + CLS.boxPadX * 2, degree * 52 + CLS.boxPadX * 2);",
  },
  {
    // 層の間隔が狭いと、線の横の区間が箱のすぐ下に寄ってラベルが重なる。層の間隔と箱の間隔を広げる
    name: "層と箱の間隔",
    skipIf: "layerSpacing: 150",
    before: "  nodeSpacing: 40,\n  layerSpacing: 60\n};",
    after: "  nodeSpacing: 56,\n  layerSpacing: 150\n};",
  },
];
const result = patches.reduce((s, { name, before, after, skipIf }) => {
  // skipIf: 後の手当てが after の行を書き換えるので、当て済みの判定はその手当てだけが入れる断片で行う
  if (s.includes(skipIf ?? after)) {
    console.log(`beautiful-mermaid: ${name} は修正済み`);
    return s;
  }
  if (s.includes(before)) {
    console.log(`beautiful-mermaid: ${name} を修正した`);
    return s.replace(before, after);
  }
  console.error(`beautiful-mermaid の ${name} の箇所が見つからない (版が変わった?)。手当てを見直す`);
  process.exit(1);
}, fs.readFileSync(p, "utf8"));
fs.writeFileSync(p, result);
JS
