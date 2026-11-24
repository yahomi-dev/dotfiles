# 作業ディレクトリの作りと規則

SKILL.md の手順の詳細。実例は `assets/example/` (架空の注文サービス)。

## 作業ディレクトリの形

```
<作業ディレクトリ>/
  README.md            図の一覧、読み方、組み立て方、日付ごとの変更の表 (assets/example/README.md が雛形)
  assemble.sh          part から mmd を組み立てる (プロジェクトごとに書く。assets/example/assemble.sh が雛形)
  page.json            HTML の題、冒頭の説明、図の並び
  src/
    1-overview.mmd     領域同士の関係 (flowchart、直接書く)
    <番号>-legend.mmd  凡例 (直接書く)
    _<領域>.part       実体の定義
    _rel-<領域>.part   関係
    _removed-<領域>.part / _removed-rel-<領域>.part   削除した実体と関係 (赤で図に残す)
    changes.json       差分の色
    <番号>-<名前>.mmd  assemble.sh が組み立てたもの (直接書かない)
  <番号>-<名前>.svg / .png   render.sh の出力
  data-model-diagrams.html / page.html   build-html.mjs の出力
  baseline-<日付>.html  前回の版のコピー (次回の基準)
```

- 図のファイル名は `<番号>-<名前>.mmd`。`render.sh` は `src/[0-9]*-*.mmd` をすべて描く。名前が `-final` で終わる図 (色なし、削除したものなしの最終版) だけは色を付けない
- 削除した実体と関係は `_removed-*.part` に分け、通常の part (`_rel-*.part` など) に混ぜない。色付きの図には混ぜ、最終版には混ぜない
- 既存の実体の中で削除した属性の行は、通常の part に残して `changes.json` の `removed.attributes` に書く。最終版を組み立てるときは `scripts/strip-removed.mjs changes.json` が標準入力からその行を落とす

## render.sh がやること

1. `setup-tool.sh`: 道具 (imxv/Pretty-mermaid-skills の beautiful-mermaid、ブラウザ不要) を `PRETTY_MERMAID_DIR` (既定は `${XDG_CACHE_HOME:-~/.cache}/pretty-mermaid-model-diff`) に無ければ固定の版で clone して `npm ci` し、箱の幅と間隔の手当て (下の「描画エンジンの制約」) を当てる
2. 色を直接指定して描画する (線 #57606a。テーマと併用すると `--line` が負ける)
3. `mark-changes.mjs` が `src/changes.json` の差分を SVG に色付けする。どの SVG にも当たらなかった項目があると、名前を出して止まる (書き間違いの検出)
4. `--png` なら色付け後の SVG から PNG (幅 1600) を作る

## 差分の色付け (src/changes.json と scripts/mark-changes.mjs)

beautiful-mermaid 1.1.3 の classDiagram は `style` / `classDef` / `cssClass` / `:::` を読まない (`:::` は名前の一部として描かれ、他の 3 つは無視される)。そこで描いた後の SVG を `mark-changes.mjs` が書き換える。同じ実体が出る図は全部塗られる。2 回当てても結果は同じ。

```json
{
  "base": "前回の版 (YYYY-MM-DD、baseline-YYYY-MM-DD.html)",
  "new":     { "entities": ["実体名"], "attributes": { "実体名": ["part に書いた行のまま"] }, "relations": ["元の実体 -> 先の実体"] },
  "changed": { "entities": [], "attributes": {}, "relations": [] },
  "removed": { "entities": [], "notes": { "実体名": ["part に書いた行のまま"] }, "attributes": {}, "relations": [] }
}
```

- `new` は緑 (箱の塗り #dcfce7・見出し #bbf7d0・枠 #16a34a、属性の文字 #15803d)、`changed` は紫 (#ede9fe・#ddd6fe・#7c3aed、#6d28d9)、`removed` は赤 (#fee2e2・#fecaca・枠 #dc2626 の破線、文字 #b91c1c に取り消し線、太字にしない)
- `removed` の実体は、表名の注記・実体名・属性の行をすべて取り消し線にする (属性を attributes に書かなくてよい)。`notes` に書いた行 (「分割先」「移動先」) だけは取り消し線を引かず赤の斜体にする。`removed` の関係は線を赤の破線にし、ラベルに取り消し線 (多重度は赤だけ)
- 実体: 箱を塗り、枠を色付きで太く。属性: その実体の中の行を色付きの太字に (「選択肢 属性名」の行も part に書いた形のまま書けばよい)。関係: 線を色付きで太く (矢じりも同じ色)、ラベルと多重度を色付きの太字に。関係は「元 -> 先」の実体名で指す (同じ 2 つの実体の間に関係が 2 本あると両方塗られる)
- 1-overview (flowchart) は、箱の中の「実体 / 実体 / ...」の行の実体名と、領域の ID (例では customers / catalog / orders) の「元 -> 先」で線とラベルを塗る
- 凡例の見本 (実体の「追加した属性」「変更した属性」「削除した属性」、新規 / 変更 / 削除した実体、その関係) も changes.json に入れる

## 次回、色を削除するとき

1. 基準にする HTML を残す: `cp data-model-diagrams.html baseline-<日付>.html` (前の baseline は残す)
2. 削除したものを part から取り除く: `_removed-*.part` を削除し、assemble.sh から `_removed-*` を外し、削除した実体の語を `ref` と 1-overview.mmd から外す。既存の実体に残した削除した属性の行も part から削除する
3. `changes.json` の new / changed / removed の中身を空にする (`{}` でよい)
4. 凡例の見本 (新規 / 変更 / 削除した実体、追加 / 変更 / 削除した属性) と「色の基準と無くなったもの」の箱は、今回の変更に合わせて残すか外す
5. 基準を変えるときは、changes.json の `base`、page.json の冒頭の説明 (色の基準と「無くなったもの」)、凡例の「色の基準」の行の 3 か所を揃える

## 描画エンジンの制約 (beautiful-mermaid 1.1.3)

- classDiagram の属性の幅は「文字数 x 0.6em」の固定計算で、日本語が枠からはみ出る。`setup-tool.sh` が `estimateMonoTextWidth` を全角 1.05em に数えるよう書き換える (erd-no-overlap スキルと共有の箇所)
- 箱の幅に `<<注記>>` の幅が入っておらず、長い表名が枠からはみ出る。`setup-tool.sh` が箱の幅の計算に注記の幅を追加する
- 線が多く出る実体は箱の幅が足りず、線の端と多重度のラベルが重なって潰れる。`setup-tool.sh` が箱の幅を「関係の本数 x 52px」以上に広げる
- 全体図では線の横の区間が箱のすぐ下に寄り、ラベルが線に乗る。`setup-tool.sh` が層の間隔 (layerSpacing) を 60 -> 150、箱の間隔 (nodeSpacing) を 40 -> 56 に広げる。図は縦に長くなる
- 当てていない手当て: ELK の線の間隔 (箱と折れ目 48、線同士 28 / 24、線と箱 36、ラベル 14) を広げる手当て。元のスクリプトは当て済みの判定に元の dist にもある文字列を使っていたため一度も当たっておらず、今の図はこの手当てなしの配置。出力を変えないため当てていない。ほかのスクリプトが同じ保存先にこの手当てを当てると図の配置が変わるので、既定の保存先を erd-no-overlap スキル (`~/.cache/pretty-mermaid`) と分けている
- 手当ての当て済みの判定は skipIf の断片で行う (後の手当てが前の行を書き換えるため)。版が変わって before が見つからなければ止まる
- 実体や関係を書く順を変えても配置はほぼ変わらない (ELK の layered)。凡例だけは関係の順で線とラベルの重なりが消えることがあるので、「別の図で定義」への関係を最後に書く
- classDiagram の `direction LR` は効かない (上から下だけ)
- 属性の行は「型 名前」の順に読まれ「名前: 型」と描かれる。空白を入れた行はこの並びになるので、1 語で書くか、この性質を使って「選択肢 属性名」と書く
- 属性に `()` を含めるとメソッドとして別の区画に入る
- `<<注記>>` は ASCII だけ。日本語だと属性として描かれる
- 別名 `class 顧客["顧客 (customers)"]` は効かない (名前だけ描かれる)
- 属性を持たない実体は空の区画が 2 段描かれる
- SVG は Inter を Google Fonts から読む (オフラインでは system-ui に落ちる)。日本語はシステムのフォント

## HTML (閲覧と PNG の保存)

```sh
node $S/scripts/build-html.mjs <作業ディレクトリ>             # data-model-diagrams.html: スタンドアロン。ブラウザで開き、各図を PNG (1x / 2x / 3x) か SVG で保存できる
node $S/scripts/build-html.mjs <作業ディレクトリ> --artifact  # page.html: claude.ai の artifact 用 (保存ボタン無し)
```

- page.json の `leads` と各図の `note` は HTML としてそのまま入る (`<code>` や色付きの `<strong>` を書ける)。`title`、`heading`、`nav` は文字列としてエスケープする。`nav` を省いた図はナビに出さない
- PNG はブラウザの中で SVG を canvas に描いて作るので、文字はその PC のフォントで描かれる (SVG の Inter は使われない)。SVG を描き直したら両方を再生成する。artifact は再度 publish する
