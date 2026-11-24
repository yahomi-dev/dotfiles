---
name: erd-no-overlap
description: Mermaid の erDiagram (beautiful-mermaid で描く物理の ER 図) で、線のラベルが線や別のラベルや表の箱に重ならないように描く手順。ラベルを短くして細部を表に出す、道具の dist に当てる手当て 6 点、間隔の引数、重なりを座標で数える検査、目視、変更前後の差分 HTML までを含む。「ER 図の文字が重なる」「ER 図を描き直して」「ER 図の差分が欲しい」と言われたら使う。このスキルの assets/example/ (架空の注文サービス) が実例。
---

# ER 図 (erDiagram) をラベルの重なりなしで描く

## このスキルのファイル

| ファイル | 役目 |
|---|---|
| `scripts/setup-tool.sh` | 描画の道具を固定の版で取得し、dist に手当て 6 点を当てる (何度実行しても 1 回だけ効く) |
| `scripts/render.sh <dir> [--wide 名前,...] [--sha256]` | ディレクトリの `*.mmd` をすべて同名の SVG に描く。最初に setup-tool.sh を呼ぶ |
| `scripts/check-overlap.mjs <svg> [-v]` | svg 1 枚のラベルごとに、他の線 / 他のラベル / 表の箱との重なりを数える |
| `scripts/erd-diff.py <before.svg> <after.svg> <out_dir>` | 2 枚の svg の構造の差を 緑 / 紫 / 赤の注記 で色付けし、単一 HTML を出す (Python 3 の標準ライブラリだけで動く) |
| `assets/example/` | 架空の注文サービスの ER 図 (`before/all.mmd` と `after/all.mmd`)。手順を一通り試すのに使う |

以下のコマンドでは `S=~/.claude/skills/erd-no-overlap` (このスキルのディレクトリ) とする。

## 道具と前提

- 道具: beautiful-mermaid (ブラウザ不要の Mermaid 描画)。imxv/Pretty-mermaid-skills (https://github.com/imxv/Pretty-mermaid-skills) の `scripts/render.mjs` から使う
- 版: コミット `e234ab73c2992f03c36db04fd55ebb90abca9c45` に固定 (その package-lock.json で beautiful-mermaid 1.1.3)。`setup-tool.sh` の `TOOL_REVISION`
- 保存先: `PRETTY_MERMAID_DIR` (既定は `${XDG_CACHE_HOME:-~/.cache}/pretty-mermaid`)。無ければ `setup-tool.sh` が clone して `npm ci` する
- 必要なもの: git、Node.js (npm)、最初の 1 回だけネットワーク。目視の PNG は道具が描く (ブラウザ不要)。HTML のスクリーンショットだけ Chrome / Chromium を使う
- **手当てを当てていない別の場所のコピーを ER に使わない** (PNG を直接描くときも、`PRETTY_MERMAID_DIR` の方の render.mjs を使う)

## プロジェクトに置くときの形 (例)

| 物 | 置き方 | 役目 |
|---|---|---|
| 生成スクリプト (任意) | スキーマの定義 (ORM のスナップショットなど) から mmd と `fk-table.md` を作る。`--check` で置いてあるものと比べる | 図を生成物にして、スキーマを変えて図の更新を忘れたら CI で止める |
| mmd / svg / 表 | 1 つのディレクトリに、全体の flowchart と凡例 (手書き)、領域ごとの図、全部の表を 1 枚に描く図 (生成)、`fk-table.md` (生成) | 正本はスキーマ。図は生成物 |
| 描画 | `sh $S/scripts/render.sh <dir> --wide <全体図の名前>`、CI で描けないなら `--sha256` で記録して比べる | |
| 重なりの検査 | `node $S/scripts/check-overlap.mjs <svg>` | 0 になるまで修正する |
| 差分 | `python3 $S/scripts/erd-diff.py` | レビュー用の HTML |

## 手順

### 1. ラベルを短くする (重なりの一番の原因)

- 線のラベルは「意味 (on delete)」まで。例: `注文した顧客 (restrict)`、`配送する注文 (cascade)`、`複合 FK (restrict)`、意味が無い線は `cascade` / `restrict` だけ
- 複合 FK の列の対応 (`(order_id, shop_id) -> (id, shop_id)`)、一意、部分一意、補足は線に書かず、`fk-table.md` (線 1 本 1 行の表) に出す。生成するなら `--check` の対象にする
- 意味の文言は生成スクリプトの対応表 (外部キーの名前ごと) に持たせ、表にだけ出す補足と部分一意の言い換えも別の対応表に分ける。文言は短く、括弧は半角、`()` を属性の行に入れない

### 2. 道具の dist に手当てを当てる (setup-tool.sh)

dist (`node_modules/beautiful-mermaid/dist/index.js`) を文字列置換で修正する。before が見つからなければ版が変わったので止まる。after が既にあれば当て済み。6 か所:

| 手当て | 理由 |
|---|---|
| 等幅の文字幅を全角 1.05em で数える (`estimateMonoTextWidth`) | 道具は「文字数 x 0.6em」で見積もるので、日本語の列名が箱からはみ出る。classDiagram と共有の箇所 (model-diff-diagram スキルも同じ手当てを当てる) |
| 箱と層の間隔に引数を使う (`Math.max(ER.nodeSpacing, _options.nodeSpacing ?? 0)` など) | 道具は erDiagram では `--node-spacing` / `--layer-spacing` を無視して固定値 (70 / 90) で描く |
| ELK の間隔を広げる (`elk.layered.spacing.edgeNodeBetweenLayers` 40、`edgeEdgeBetweenLayers` 24、`elk.spacing.edgeNode` 32、`edgeEdge` 20、`edgeLabel` 12) | 線同士と線と箱と線と文言の間隔が既定のままで文言が別の線に重なる |
| ELK が決めたラベルの位置を残す (`labelPosition` を relation に持たせる) | 道具は ELK の位置を捨てて経路の中点に描く |
| ラベルを線の上に載せる (edge.labels の layoutOptions で inline) | 線の横に置くと平行な 2 本の間でどちらの線のものか読めない |
| 描くときに `rel.labelPosition ?? midpoint2(rel.points)` | 残した位置で描く (無ければ従来どおり) |

classDiagram (論理モデル) 用の手当ては、等幅の文字幅を除いて別の箇所なので重ならない。同じ保存先に両方を当ててよく、どちらを先に実行してもよい。

### 3. 間隔の引数

全部の表を 1 枚に描く図は `--node-spacing 100 --layer-spacing 200` (`render.sh` の `--wide` で指定する)。領域ごとの図は既定でよい (重なれば同じ引数を追加する)。図が大きくなるのは許容する。

```sh
sh $S/scripts/render.sh docs/erd --wide all,all-relations
```

### 4. 重なりを座標で数える (目視の前に)

```sh
node $S/scripts/check-overlap.mjs docs/erd/all.svg      # NG の行と合計
node $S/scripts/check-overlap.mjs docs/erd/all.svg -v   # 全ラベル
```

ラベルの箱 (rx="2" の rect + text) ごとに、自分の線までの距離、他の線が箱を横切るか、他のラベルの箱と重なるか、表の箱と重なるかを見て、1 つでも当たれば NG。全 svg で 0 になるまで 1〜3 を調整する (まずラベルを短く、次に間隔)。

### 5. 目視

```sh
T=${PRETTY_MERMAID_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pretty-mermaid}
node $T/scripts/render.mjs --input docs/erd/all.mmd --output /tmp/all.png --format png --width 2400 --theme github-light --node-spacing 100 --layer-spacing 200
```

PNG を Read で見る。HTML に埋めたものは `google-chrome --headless=new --disable-gpu --no-sandbox --hide-scrollbars --window-size=1600,3000 --screenshot=<png> file://<絶対パス>` で撮る (パスは絶対で。cwd が変わると ERR_FILE_NOT_FOUND)。

### 6. 変更前 -> 変更後の差分 HTML (レビュー用)

```sh
mkdir -p <作業ディレクトリ> && cd <作業ディレクトリ>
git -C <リポジトリ> show <基準のコミット>:docs/erd/all.svg > baseline-<短い hash>-all.svg
git -C <リポジトリ> show main:docs/erd/all.svg > main-<短い hash>-all.svg
python3 $S/scripts/erd-diff.py baseline-*.svg main-*.svg . --title "ER 図の差分 (YYYY-MM-DD)" --base-label "基準: ... 今の版: main"
```

- 読み取りは svg の構造から (表 = `g.entity` の data-id、列 = text の行、線 = `polyline.er-relationship` の data-*)
- 線は構造 (2 表、多重度の組、on delete、識別) で比べる。**ラベルの文言だけの変更は色を付けず**、一覧の末尾の区分 (折りたたみ) に出す。改名は「削除 + 追加」で出る
- 削除したものは after の図に無いので、図の下の赤い枠に一覧で書く
- HTML は図を縮めず原寸 + 横スクロール。Google Fonts の `@import` は削除する (単一ファイルで外部の読み込みを無くす)
- 出力: `erd-all-final.svg`、`erd-all-diff.svg`、`erd-diff-<日付>.html`。`--date` を省くと今日の日付

### 7. 共有

Downloads などにコピーするのは、最終の svg / png、差分の svg、差分の HTML、領域ごとの svg、README と fk-table.md。HTML と svg に決定番号、MR 番号、課題 ID、エージェントの話を書かない。

## 実例で試す

```sh
cp -r $S/assets/example /tmp/erd-example && cd /tmp/erd-example
sh $S/scripts/render.sh before --wide all && sh $S/scripts/render.sh after --wide all
node $S/scripts/check-overlap.mjs after/all.svg -v
python3 $S/scripts/erd-diff.py before/all.svg after/all.svg out --title "ER 図の差分 (例)" --base-label "基準: before。今の版: after"
```

表の追加 (shipments)、削除 (coupons)、列の追加 / 変更 / 削除、多重度の変更 (orders -> order_items)、ラベルの文言だけの変更 (customers -> addresses) が 1 枚に出る。

## 落とし穴 (実際に踏んだもの)

- 引数の `--node-spacing` / `--layer-spacing` が erDiagram では無視されていた (手当てで修正するまで、指定が効いていなかった)
- 等幅の文字幅の手当てが無いと、日本語の列名の行が箱からはみ出る。classDiagram 用に当てた保存先で描いた図と、ER 用の手当てだけの保存先で描いた図は、列の幅が違う (今は setup-tool.sh が両方を当てる)
- ラベルを太字にすると枠からはみ出す。色だけ変える
- FK の意味の文言に `(restrict)` を書くと、生成が追加する on delete と重なって `(restrict) (restrict)` になる。意味だけ書く
- 単一 HTML に埋めた svg の `@import url(fonts.googleapis.com)` は外部の読み込みになる。削除するとフォントは手元のものに落ちるが問題ない
- 作業ツリーが別ブランチのとき、比較の元は `git show main:` で取る (作業ツリーの svg は未コミットの変更を含む)
- PostgreSQL の複合 FK と NULL の説明をこの図で行うときは、`?` (NULL 可) の列と単独 FK の有無を見せる。単独 FK の印は各列の FK バッジ、複合 FK は線のラベル

## プロジェクトに組み込むなら

1. `check-overlap.mjs` を生成の最後に流し、重なりが 0 でなければ失敗にする
2. `erd-diff.py` を `<基準の ref>` を受け取るコマンド (just のレシピなど) にする
3. 手当て 6 点を道具の fork か patch ファイルにする (版が上がったら before が見つからず止まるので、そのとき見直す)
