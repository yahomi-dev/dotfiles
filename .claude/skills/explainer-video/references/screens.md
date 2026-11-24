# モック画面の部品 (ui 場面の screen.html)

画面録画ではなく、その瞬間の画面を HTML で描く。実物のスクリーンショットを見ながら、構造と文言を合わせたモックを書く (見た目は似ていればよい。文言と数字は RECORD から取る)。
部品の CSS は engine/style.css にある。足りないものは `html` の中に `<style>` を書いて足してよい (class 名は衝突しないよう接頭辞を付ける)。

## 決まり

- 動かす要素に `data-id` を付ける (`click` / `type` / `show` / `zoom` の対象)
- 最初から隠す要素に `data-hidden` を付ける (後で `show` する吹き出し、結果、トースト)
- `<input>` / `<textarea>` は使わず、`.field` の div に文字を入れる (本物の入力欄はフォーカス枠やキャレットが録画に混ざる)
- 画面は 1 場面 1 状態。操作で状態が変わるなら、その変化は `show` / `set` / `cls` で起こす。大きく変わるなら次の ui 場面に分ける
- 文字は実物の文言を使う。架空の例を置かない

## 枠

| frame | 用途 |
|---|---|
| `browser` | Web アプリ。上に URL 欄 (`screen.url`) |
| `app` | デスクトップアプリ。上にタイトル (`screen.title`) |
| `phone` | スマホ (360×700、黒い縁) |
| `none` | 枠なし (画面の一部だけ見せる、スライド風) |

## 業務アプリ (2 ペイン)

```html
<div class="app">
  <div class="app-header"><span class="logo"></span>アプリ名<span class="spacer"></span><span class="avatar"></span></div>
  <div class="app-body">
    <div class="pane">
      <div class="pane-title">入力</div>
      <div class="field multiline" data-id="input">貼り付けてください</div>
      <div class="row right"><button class="btn primary" data-id="go">実行</button></div>
    </div>
    <div class="pane">
      <div class="pane-title">結果</div>
      <div class="card" data-id="result" data-hidden>
        <div class="card-title">3 件</div>
        <div class="list">
          <div class="item" data-id="r0" data-hidden><span class="num">1</span><span>結果の 1 行目</span></div>
        </div>
      </div>
    </div>
  </div>
  <div class="toast" data-id="toast" data-hidden>保存しました</div>
</div>
```

| class | 見た目 |
|---|---|
| `.app` / `.app-header` / `.app-body` | 全体 (縦積み) / ヘッダー (ロゴ・名前・アバター) / 本体 (横並び) |
| `.pane` / `.pane-title` | 列 / 列の見出し |
| `.field` / `.field.multiline` | 入力欄 (薄い文字 = プレースホルダ)。`type` で打ち込むと `.typed` が付いて濃くなる |
| `.btn` / `.btn.primary` / `.btn.small` | ボタン。クリック中は `.pressed` |
| `.row` / `.row.right` | 横並び / 右寄せ |
| `.card` / `.card-title` | 枠つきの区画 |
| `.list` / `.item` / `.item .num` | 一覧 / 行 / 番号の丸 |
| `.tag` | 小さなラベル |
| `.toast` / `.toast.top` | 右下 (または右上) の通知 |
| `.muted` | 薄い文字 |
| `.mark` | 強調 (アクセント色の枠) |

## チャット

```html
<div class="app">
  <div class="app-header"><span class="logo"></span>問い合わせチャット</div>
  <div class="app-body"><div class="pane">
    <div class="chat">
      <div class="msg user" data-id="m1" data-hidden>先週届いた靴を返品したい</div>
      <div class="msg bot" data-id="m2" data-hidden>返品を承ります。注文番号を教えていただけますか？</div>
    </div>
    <div class="row" style="margin-top: auto">
      <div class="field" style="flex: 1" data-id="input">メッセージを入力</div>
      <button class="btn primary" data-id="send">送信</button>
    </div>
  </div></div>
</div>
```

打ち込んで送る流れ: `{ at: 1, type: 'input', text: '...' }` -> `{ at: 4, click: 'send', zoom: 1.4 }` -> `{ at: 4.1, set: 'input', text: '' }` + `{ at: 4.1, show: 'm1' }` -> `{ at: 6, show: 'm2' }`。

## 表

```html
<table class="table">
  <tr><th>名前</th><th>件数</th><th>状態</th></tr>
  <tr data-id="row1"><td>山田</td><td>12</td><td><span class="tag">完了</span></td></tr>
</table>
```

行を `mark` すると枠が付く。数字を変えるなら `set` で差し替える (`<td data-id="c1">`)。

## 自前の見た目を足す

```html
<style>
  .mx-kpi { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
  .mx-kpi .v { font-size: 32px; font-weight: 700; }
</style>
<div class="mx-kpi"> ... </div>
```

CSS の `transition` / `animation` は書かない (style.css が全面無効化している。動きはすべて events で t から決める)。
`show` / `hide` の対象には inline の `opacity` が毎コマ書かれるので、自前 CSS の `opacity` はその要素には効かない。薄く見せたい行は `cls` で class を付け、子要素に `opacity` を掛ける (`.mx-row.out > span { opacity: 0.3 }`) か色を変える。
