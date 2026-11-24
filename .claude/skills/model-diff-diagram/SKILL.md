---
name: model-diff-diagram
description: データモデル図 (論理モデル、Mermaid classDiagram) を「前回の版からの差分が色で分かる形」(緑 = 追加、紫 = 変更、赤の破線 + 取り消し線 = 削除) のスタンドアロン HTML に描き直す。「前みたいに差分がわかる形で」「前回の状態からの差分」「データモデル図を更新して」「色付きの図」と言われたら使う。このスキルの assets/example/ (架空の注文サービス) が実例で、作業ディレクトリの src/*.part + changes.json + page.json と、scripts/ の render.sh + build-html.mjs のスクリプトをそのまま使う。
---

# データモデル図の差分版 (色付き) を作る

## 成果物

- SVG (領域ごと + 全体 + 凡例 + 最終版) と、それを 1 ページに並べたスタンドアロン HTML `data-model-diagrams.html` (ブラウザで開くだけ。各図を PNG / SVG で保存できる)
- `page.html` (claude.ai の artifact 用。保存ボタン無し)
- `baseline-<前回の日付>.html` (直前の版のコピー。次回の基準)
- 作業ディレクトリの README.md の「<日付> の変更」の表 (区分 / 内容)

## このスキルのファイル

| ファイル | 役目 |
|---|---|
| `scripts/setup-tool.sh` | 描画の道具を固定の版で取得し、classDiagram の箱の幅と間隔の手当て 4 点を当てる (何度実行しても 1 回だけ効く) |
| `scripts/render.sh [<作業ディレクトリ>] [--png]` | `src/<番号>-<名前>.mmd` をすべて SVG に描き、`mark-changes.mjs` で差分の色を付ける。`--png` で確認用の PNG も作る |
| `scripts/mark-changes.mjs` | `src/changes.json` の差分を SVG に塗る。当たらない項目があれば名前を出して止まる |
| `scripts/strip-removed.mjs` | 最終版の mmd から、既存の実体に残した削除した属性の行を落とす (assemble.sh が使う) |
| `scripts/build-html.mjs [<作業ディレクトリ>] [--artifact]` | `page.json` の並びで SVG を 1 ページの HTML にする (`save-buttons.js` は保存ボタンの処理) |
| `references/guide.md` | 作業ディレクトリの作り、changes.json の詳細、次回色を削除する手順、描画エンジンの制約。**最初に全部読む** |
| `assets/example/` | 架空の注文サービスの作業ディレクトリ (part、changes.json、page.json、assemble.sh、README.md)。新しく始めるときはこれをコピーする |

以下のコマンドでは `S=~/.claude/skills/model-diff-diagram` (このスキルのディレクトリ) とする。

## 道具と前提

- 道具: beautiful-mermaid (ブラウザ不要の Mermaid 描画)。imxv/Pretty-mermaid-skills (https://github.com/imxv/Pretty-mermaid-skills) の `scripts/render.mjs` と `scripts/png.mjs` を使う
- 版: コミット `e234ab73c2992f03c36db04fd55ebb90abca9c45` に固定 (その package-lock.json で beautiful-mermaid 1.1.3)。`setup-tool.sh` の `TOOL_REVISION`
- 保存先: `PRETTY_MERMAID_DIR` (既定は `${XDG_CACHE_HOME:-~/.cache}/pretty-mermaid-model-diff`)。無ければ `setup-tool.sh` が clone して `npm ci` する。erd-no-overlap スキルと既定の保存先を分けている理由は `references/guide.md` の「描画エンジンの制約」
- 必要なもの: git、Node.js (npm)、最初の 1 回だけネットワーク。ブラウザは不要

## 初めて使うとき

```sh
cp -r $S/assets/example <作業ディレクトリ> && cd <作業ディレクトリ>
sh assemble.sh && sh $S/scripts/render.sh . --png && node $S/scripts/build-html.mjs .
```

実例の実体と part を自分のモデルに置き換え、assemble.sh の `ref` の対応表 (実体名 -> 物理の表名) と組み立ての行、page.json の題と図の並び、README.md の図の一覧を書き換える。

## 手順 (2 回目以降)

0. `cp data-model-diagrams.html baseline-<前回の日付>.html` (前の baseline は残す)
1. 前回の差分を削除する (`references/guide.md` の「次回、色を削除するとき」): `_removed-*.part` を削除し、既存の実体に残した削除した属性の行を削除し、1-overview の削除した語を削除し、`changes.json` を空の形に
2. 今回の変更を part に入れる。削除する実体は `_removed-<領域>.part` に移して「分割先 / 移動先: X」の行を追加する (changes.json の `removed.notes` に書くと取り消し線なしの赤の斜体)。削除する関係は `_removed-rel-<領域>.part`。assemble.sh (ref の対応表、cat する part) を今の形に修正してから `sh assemble.sh` で mmd を組み立てる
3. `changes.json` の `base`、`page.json` の冒頭の説明 (色の基準と「無くなったもの」)、凡例の mmd の「色の基準」の行と「無くなったもの」の箱、の 3 か所を今回の基準に揃える
4. `sh $S/scripts/render.sh . --png` -> `node $S/scripts/build-html.mjs .` -> `node $S/scripts/build-html.mjs . --artifact`
5. PNG を Read で見て確認する (色が意図どおりか、ラベルと線の重なり)。重なりは関係を書く順を変えるか、`references/guide.md` の「描画エンジンの制約」の範囲で手当てする
6. README に「## <日付> の変更 (基準は <前回の版>、baseline-<日付>.html)」の表を追加し、前回の表は見出しに「(経緯。色付きの図は baseline-<日付>.html)」と添えて残す。見出しの「<日付> 更新」も修正する
7. 共有: page.html を前回と同じ artifact に再度 publish する (前回の URL を渡して更新する)。publish の前に page.html の本文と SVG の文字を python で全部取り出して目を通す (300 KB を丸ごと Read しない)。共有用のページなど外向けの場所は、ユーザが求めたときだけ更新する

## 判断の実例

- 前回の版に無かった関係 (どちらの実体も前回からあるが、線を新しく引いた場合) は「ラベルを変える (紫)」ではなく「追加 (緑)」。紫は前回の版にあったものの名前や形を変えたときだけ
- 凡例の説明は 1 行 1 語に寄せる。属性の行に空白が入ると「型 名前」と読まれて逆さに描かれる

## 色の規則 (changes.json)

```json
{
  "base": "前回の版 (YYYY-MM-DD、baseline-YYYY-MM-DD.html)",
  "new":     { "entities": [], "attributes": { "実体": ["part の行のまま"] }, "relations": ["元 -> 先"] },
  "changed": { "entities": [], "attributes": {}, "relations": [] },
  "removed": { "entities": [], "notes": { "実体": ["移動先の実体 移動先"] }, "attributes": {}, "relations": [] }
}
```

- 緑 = 今回追加した実体・属性・関係。新規の実体の属性の行は塗らない (箱ごと新規)
- 紫 = 名前や形を変更した実体・属性・関係。関係は端の実体の名前が変わっただけなら塗らない
- 赤の破線 + 取り消し線 = 削除した実体・属性・関係 (図に残して見せる)。削除したものの後継は緑
- 凡例の見本 (新規 / 変更 / 削除した実体、追加 / 変更 / 削除した属性、関係) も changes.json に入れる
- 1-overview (flowchart) は箱の中の語と領域 ID (例では customers / catalog / orders) の「元 -> 先」で塗る

## 書き方の制約 (Mermaid classDiagram、beautiful-mermaid)

- 属性は業務上の意味がある項目だけ (型・主キー・外部キーの列・on delete は書かない)。関係は動詞 (読む向き) と多重度
- 属性の行は「型 名前」の順に読まれ「名前: 型」と描かれるので、1 語で書くか「選択肢 属性名」の形を使う。`()` はメソッドになる。`<<注記>>` は ASCII だけ。別名は効かない。`direction LR` は効かない。`style` / `classDef` / `:::` は読まない (色は後処理)
- 点線は外部キーを張らない参照
- 図と HTML の文言に 決定番号、MR 番号、課題 ID、エージェントの話を書かない (上司や関係者に見せる資料になる)。README には書いてよい
- 括弧は半角 ()、矢印は ->、日付は YYYY-MM-DD

## 委譲

定型なので sonnet のサブエージェントに任せてよい。依頼文には「今回の変更 (削除 / 追加 / 変更 / 凡例)」「手順 0〜6」「制約」「報告 (作ったファイル、色を付けた項目、PNG で確認した結果)」を入れ、`references/guide.md` と作業ディレクトリの README を最初に全部読ませ、削除前の `_removed-*.part` と `changes.json` を実例として読ませる。入れ子のサブエージェントは使わせない。
