# timeline.js の書式

`window.TIMELINE = { ... }` に場面 (scenes) を順に並べる。座標・時刻の補間はすべて engine/*.js がやるので、ここには「何が映り、何秒目に何が起きるか」だけを書く。
数字と文は data.js の `window.RECORD` (実物を 1 回流した記録) から取る。見本は assets/template/timeline.js。

目次: 全体 / 場面に共通の項目 / title・outro / ui / events の語彙 / mech / arch / custom / 時刻表と確認

## 全体

| 項目 | 必須 | 意味 |
|---|---|---|
| `scenes` | ✓ | 場面の並び。上から順に再生 |
| `fps` | | 既定 30 |
| `theme` | | `{ bg, dot, card, fg, dim, accent, edge, font, mono }` の一部だけ上書き。既定は暗い背景 + 水色のアクセント |
| `labels` | | 小見出しの自動番号の語。既定 `{ ui: '操作', mech: '仕組み', arch: '仕組み' }` |
| `poster` | | ポスター画像を撮る秒。既定は最初の ui 場面の 1.5 秒後 |

## 場面に共通の項目

| 項目 | 意味 |
|---|---|
| `kind` | `title` / `ui` / `mech` / `arch` / `outro` / `custom` |
| `id` | `node tools/render.mjs scene <id>` で指す名前 (任意) |
| `dur` | 滞在秒 (既定 4)。場面の切り替えは 0.4 秒のクロスフェード |
| `kicker` | 字幕の上の小見出し。省略すると `操作 1` `仕組み 1` のように自動で番号が付く |
| `caption` | 字幕。1 文 20 字前後 (36px で収まる上限は約 40 字)。events の `caption` で途中から差し替えられる |
| `color` | 小見出しの色 (既定 `theme.accent`) |
| `transition` | `'cut'` でフェードなしの切り替え |
| `events` | 出来事の並び (下記)。ui / mech / arch / custom で使える |

尺の目安: タイトル 3 秒、操作 8〜10 秒、仕組み 6〜11 秒、締め 4 秒。全体で 40〜70 秒。

## title / outro

```js
{ kind: 'title', dur: 3, title: '「議事録まとめ」は何をしているのか', subtitle: '1 回の操作を、画面と仕組みで交互に追う' }
{ kind: 'outro', dur: 4, title: 'AI は文に点を付けるだけ。区切りと並べ替えはプログラム。', subtitle: '5 文 -> 3 件、840 ms' }
```

`title` の代わりに `html` を書くと装飾できる。outro の `title` が「伝えたい 1 文」になる。

## ui (操作の場面)

```js
{
  kind: 'ui', id: 'paste', dur: 10, caption: '議事録を貼り付けて「まとめる」を押す',
  screen: { frame: 'browser', url: 'minutes.example.app', html: screen() },
  cursor: { x: 1120, y: 600 },
  events: [
    { at: 0.5, move: 'input' },
    { at: 1.2, type: 'input', text: R.input, cps: 40, zoom: 1.35 },
    { at: 4.6, zoom: 'reset' },
    { at: 5.8, click: 'go', zoom: 1.6, caption: '押した瞬間、裏で処理が始まる' },
  ],
}
```

| 項目 | 意味 |
|---|---|
| `screen.frame` | `browser` (URL 欄つき、既定) / `app` (タイトルつき) / `phone` (縦 360×700) / `none` (枠なし) |
| `screen.url` / `screen.title` | 窓の上に出す URL / タイトル |
| `screen.w`, `h`, `x`, `y` | 窓の大きさと位置 (既定 1180×660 を字幕帯の上の領域 1600×730 の中央に) |
| `screen.html` | 画面の中身の HTML。動かす要素に `data-id`、最初から隠す要素に `data-hidden` を付ける。部品は references/screens.md |
| `cursor` | カーソルの最初の位置 (既定は右下寄り)。`false` で出さない |
| `mount(root, ctx)` | HTML を置いた後に呼ばれる (任意。DOM を直接いじりたいとき)。ui / mech / custom の全部にある |

`show` / `hide` の対象は毎コマ inline の `opacity` で上書きされるので、自前 CSS の `opacity` はその要素には効かない。薄くしたいなら子要素に掛けるか、色を変える。

同じ画面を 2 つの操作場面で使うなら、状態を引数にした関数 (`screen({ results: true })`) で HTML を作り、場面ごとに違う状態を渡す。

## events の語彙 (ui / mech / arch / custom 共通)

1 つの出来事に複数の項目を書ける (`{ at: 5.8, click: 'go', zoom: 1.6, caption: '...' }`)。`at` は場面の開始からの秒。

| 項目 | 値 | 意味 |
|---|---|---|
| `show` / `hide` | id か `[id, ...]` | 出す / 消す。`fade` 秒 (既定 0.35)。最初の出来事が `show` の要素は初期状態で隠れる |
| `move` | id | カーソルを要素の中心へ。`dur` 秒 (既定 0.6)。`dx`, `dy` でずらす |
| `click` | id | `at` の時刻に要素に着いて押す (直前 0.6 秒で動いてくる)。押し込みと波紋が出る |
| `type` | id | 要素に `text` を打ち込む。`cps` 文字/秒 (既定 18)。打ち終わって 0.8 秒はカーソル点滅 |
| `set` | id | 要素の文字を `text` に差し替える (瞬時) |
| `cls` | id | `add` / `remove` に書いた class を付け外し |
| `mark` / `unmark` | id | 強調する (class `mark`。枠 / 札の塗り / 行の色になる) |
| `zoom` | 数値 | その出来事の対象 (`click` / `move` / `type` の要素) へ寄る倍率。1.3〜1.8 が自然 |
| | `'reset'` | 等倍に戻す |
| | `{ to, scale, x, y, dur, delay }` | 寄る先の id か座標、倍率、かかる秒 (既定 0.7)、遅れ |
| `caption` / `kicker` | 文字列 | 字幕 / 小見出しをここから差し替える |

カメラの視野は字幕帯を除いた 1600×730 なので、ズームしても画面が字幕に重ならない。視野の外に出る寄り方は自動で内側に寄せられる。

## mech (仕組みの場面)

入力されたデータを画面いっぱいに広げ、処理の動きを見せる。`items` に部品を縦に並べ (既定は中央寄せの縦積み)、`events` で動かす。

```js
{
  kind: 'mech', id: 'rank', dur: 11, caption: 'AI の点数で並べ替え、上位 3 文を残す',
  items: [
    { id: 'bars', type: 'bars', color: AI, max: 1, items: R.sentences.map((s, i) => ({ label: s, value: R.scores[i], text: R.scores[i].toFixed(2) })) },
    { id: 'note', type: 'note', html: `上位 <b>${R.picked.length} 文</b> を要点として返す` },
  ],
  events: [
    { at: 0.3, show: 'bars', stagger: 0.3 },
    { at: 3.4, sort: 'bars', by: 'value', desc: true, dur: 1.0 },
    { at: 4.8, mark: 'bars', index: R.picked },
    { at: 5.4, show: 'note' },
  ],
}
```

### items (部品)

共通: `id`、`type`、`visible: true` (最初から出す)、`x`, `y` (`layout: 'free'` のとき絶対位置)、`w` (最大幅)

| type | 項目 | 見た目と動き |
|---|---|---|
| `text` | `text` か `html`、`size` (既定 34)、`color` | 大きな文章。`split` で小さく薄くなる |
| `note` | `text` か `html`、`size` (既定 24) | 補足の一文 (薄い色。`<b>` はアクセント色) |
| `html` | `html` | 自由な HTML (表のような行の並びに)。中の `data-id` 付き要素は events で個別に指す。順に出すなら `rows.map((r, i) => ({ at: 0.5 + i * 0.3, show: `row${i}` }))` のように events を生成する |
| `chips` | `items: ['文', ...]` か `[{ text, color }]`、`color`、`size`、`gap` | 札の並び。`show` で 1 つずつ出る。子は `id.0`, `id.1` …。判定で色を変えるなら最初は同じ色にし、`cls` で class を付けて `<style>` の `.chip.ng { --c: #f87171 }` で上書きする (最初から色分けすると結果が先に分かる) |
| `bars` | `items: [{ label, value, text, color }]`、`max`、`color`、`rowH` (既定 48)、`labelW` (既定 520)、`w` (既定 1200) | 横棒グラフ。`show` で棒が伸び、`sort` で並び替わる。子は `id.0` … |
| `number` | `unit`、`from` (既定 0)、`format(v)` | 大きな数字。`count` で増える |
| `boxes` | `items: [{ id, label, sub, color, w }]`、`gap`、`arrows: false` | 箱の並び (左から右へ矢印)。`flow` で光る札が運ばれる。子は `id.<boxId>` |

### mech だけの出来事 (糖衣)

| 項目 | 意味 |
|---|---|
| `split: 'src', into: 'chips', stagger` | 文章を小さく薄くし、札を 1 つずつ出す (`stagger` 秒おき、既定 0.2) |
| `show: 'chips'` / `show: 'bars'` | 子を `stagger` 秒おきに順に出す |
| `sort: 'bars', by: 'value' \| 'label', desc, dur` | 並び替え (既定: value の降順、0.8 秒)。`order: [2, 0, 1]` で並びを直接指定 |
| `count: 'n', to, from, dur` | 数字を増やす (既定 1 秒) |
| `flow: 'boxes', from: 'a', to: 'b', dur, color, text, arc` | 箱 a から b へ光る札を運ぶ (既定 0.8 秒)。`text` は札の名前、`arc` は山なりの高さ px |
| `index: 1` / `index: [1, 3]` | `mark` / `cls` / `show` の対象を子要素 (`id.1`) にする |

部品は字幕帯の上 730px に収める。入り切らないときは `size` を下げるか、場面を 2 つに分ける。

## arch (構成図の場面)

全体の構成図のうち、いま関係する部分だけを差し込む。ノードは 3〜6 個。

```js
{
  kind: 'arch', dur: 6, caption: '区切った文を 1 つずつ AI に渡して、点数をもらう',
  grid: [3, 1],
  nodes: [
    { id: 'web', label: 'ブラウザ', sub: 'お客様の画面', color: CU, col: 0, row: 0 },
    { id: 'api', label: 'サーバー', sub: 'プログラム', color: PG, col: 1, row: 0 },
    { id: 'ai', label: 'AI', sub: '採点だけ', color: AI, col: 2, row: 0, tag: 'gpt' },
  ],
  edges: [{ from: 'web', to: 'api' }, { from: 'api', to: 'ai', dashed: true, label: '1 文ずつ' }],
  focus: ['api', 'ai'],
  flow: [['api', 'ai'], ['ai', 'api']],
  hop: 0.6,
  badges: [{ node: 'ai', text: '重要度 0〜1 を返す', at: 2.4 }],
}
```

| 項目 | 意味 |
|---|---|
| `grid` | `[列数, 行数]`。既定 `[3, 2]`。`col` / `row` は 0 始まりで小数も可 |
| `nodes[]` | `id`、`label`、`sub` (役割)、`tag` (右上のピル)、`color` (同じ役割は同じ色)、`col`、`row`、`w`、`h`。並び順 = 登場順 |
| `edges[]` | `from`、`to`、`dashed` (常時ではない呼び出し)、`label` |
| `focus` | 明るくするノード。他は暗くなる |
| `flow` | 粒が流れる区間の並び `[[from, to], ...]`。尺がある限り繰り返す |
| `hop` | 1 区間を流れる秒 (既定 0.8。軽い処理は 0.5、重い処理は 1.0) |
| `badges[]` | `{ node, text, at }`。同じノードの次のバッジが出るまで表示 |
| `title` / `subtitle` | 左上の見出し (任意) |

同じ構成図を複数の場面で使うなら `const ARCH = { grid, nodes, edges }` を作って `{ kind: 'arch', ...ARCH, focus: [...], flow: [...] }` と広げる。

## custom (自由な場面)

部品で表せない演出を書く。`render` は `lt` (場面の開始からの秒) だけから絵を決める。乱数・実時間・前のコマの状態は使わない (使うと撮り直すたびに絵が変わる)。CSS の transition / animation は全面禁止 (style.css で無効化済み)。

```js
{
  kind: 'custom', dur: 6, caption: '...',
  mount: (root, ctx) => {
    const box = EV.h('div', { class: 'm-text', 'data-id': 'x', text: '...' });
    root.append(box);
    return { box };
  },
  render: (lt, root, ctx, api) => {
    api.box.style.opacity = EV.easeOut(EV.ramp(lt, 0.3, 0.8));
  },
  events: [{ at: 2, zoom: { to: 'x', scale: 1.5 } }],
}
```

`EV` の小道具: `h(tag, attrs, children)`、`svg`、`clamp`、`ramp(t, a, b)`、`lerp`、`easeOut`、`easeInOut`、`easeBack`。`ctx` は `{ theme, measure, W, H }`。

## panel (常時パネル)

場面をまたいで見せ続けるもの (履歴の図、地図、進み具合) をカメラの外、字幕の上に置く。`TIMELINE.panel = { mount, render }` を書き、場面ごとの状態は各場面の `panel: {...}` に書く (中身は自由。`render` に `scene.panel` として渡る)。`panel: false` の場面では消える (クロスフェード)。

```js
window.TIMELINE = {
  panel: {
    mount: (root, ctx, scenes) => { /* SVG や DOM を root に作る。scenes (t0 / t1 付き) から「いつ何が現れるか」を前計算して返す */ return api; },
    render: (t, root, ctx, { scene, lt, scenes, api }) => { /* t (全体の秒) と scene.panel から絵を更新する */ },
  },
  scenes: [
    { kind: 'title', panel: false, ... },
    { kind: 'ui', panel: { commits: ['c1'], at: 9.2 }, ... },   // at = この場面の何秒目に状態が変わるか
  ],
};
```

- パネルの領域は `.panel` (1600×730)。ui 場面は `screen.x` / `screen.w` で窓を左に寄せ、mech 場面は `padding: '40px 560px 40px 60px'` で右を空ける
- 状態は前の場面から引き継ぐ形にすると書きやすい (mount で scenes を前から畳み込み、場面ごとの解決済み状態を持つ)。実例: Git の履歴の図 (コミットの登場時刻 = 最初に現れる場面の t0 + at、ブランチの付箋は前の場面の位置から今の位置へ補間)
- ズームはパネルの下に潜るので、パネルがある構成では倍率を 1.1〜1.2 に抑える

## 時刻表と確認

```bash
node tools/render.mjs info              # 尺と場面の時刻表 (番号と id)
node tools/render.mjs sheet 16          # out/sheet.png 全体を 16 コマ
node tools/render.mjs scene 3 8         # out/scene-3.png その場面だけ 8 コマ (id でも指せる)
node tools/render.mjs stills 6.5,44.9   # out/still-<秒>.png 原寸
```

出来事の `at` を決めるときは、字幕のタイプが終わる時刻 (文字数 × 0.035 + 0.1 秒) と、`show` / `move` / `zoom` の所要秒を足し合わせて、見る人が追える間隔 (0.4 秒以上) を空ける。
