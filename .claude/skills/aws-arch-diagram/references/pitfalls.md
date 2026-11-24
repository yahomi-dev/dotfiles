# 落とし穴 (1 度ずつ踏んだもの)

## PNG 化 (headless Chromium)

- Chromium は playwright が取得したもの (`~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`) を直接叩く。`chromium_headless_shell-*` の方は `headless_shell` バイナリが無いことがある。`render_png.sh` が最新版を自動で選ぶ
- `--headless=new --no-sandbox --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=W,H --screenshot=out.png file://...` で、SVG を `width="W" height="H"` にした standalone HTML を撮る。`export_figures` がその HTML と `.size` を作る
- Web フォント (Google Fonts) は `--virtual-time-budget=10000` を付けないと読み込み前に撮れてシステムフォントになる
- **`.size` を `read w h < file && ...` と繋ぐと止まる。** 末尾改行が無いと `read` が非 0 を返すため。`;` で繋ぐか `|| true` を付ける (`export_figures` は改行付きで書くようにしたが、他人のファイルでは注意)。スクショが「更新されたはずなのにサイズが同じ」ときはこれを疑う
- Chrome が黙って落ちたときは `--user-data-dir=/tmp/xxx` を付けてプロファイルのロック競合を避ける

## SVG / HTML

- アイコンは `<symbol id="ic-x"><image href="data:image/svg+xml;base64,..."/></symbol>` で埋め、`<use href="#ic-x">` で参照する。defs はページ先頭の非表示 svg (`position:absolute;width:0;height:0`) に 1 回だけ置く。`display:none` にすると参照が効かないブラウザがある
- 公式 SVG の viewBox: Arch_*_64 は `0 0 80 80`、Res_*_48 は `0 0 48 48`、グループ *_32 は `0 0 40 40`。symbol の viewBox を合わせないと縮んで表示される
- 同じ id の `<defs>` を複数の svg に書くと id が衝突する。図を増やしたら defs は共有のまま、各 svg からは削る
- `<text>` の `<` `&` はエスケープする (`html.escape`)。`<ref_slug>` のような表記で壊れやすい
- 線のラベルは `paint-order: stroke; stroke: #fff` で白ふちを付けると線の上に置ける。ただし枠の塗り (`.manual` など) の上では ふちが白くなるので、枠の塗りに合わせる
- 要素は描画順に重なる。枠の塗りの後に線や文字を描く (利用者を `<g>` の前に描いて枠に隠れた例あり)

## レイアウト

- 文字幅は英数 0.55em、日本語 1.0em で見積もり、枠からはみ出さないか PNG で確認する。IAM のポリシー説明のような長文は 2 行に割るか短くする
- 枠の見出し行と内側の枠の間は 40px 以上 (10px だと詰まって見える)
- 枠の左端にアイコンを置くとラベルが枠線に乗る。枠の左端からアイコン中心まで 90px 以上取る
- 縦の幹線は複数引くなら 30px ずつずらす (重なると見えない)
- 利用者の線のラベルは水平部分の中央に置く (折れ角の近くだと縦線と重なる)

## Artifact / 配布

- Artifact の表示枠はページが起こすダウンロードを止める。「画像で保存」は `<a href="img/x.png" target="_blank">` で新しいタブに開かせ、右クリック保存にする。確実なのはローカルファイル
- 組織のネットワークによっては claude.ai に接続できない (接続拒否)。その場合、成果物は `Downloads/<project>-infra-diagram/` (HTML + `img/`) と作業用のディレクトリに置いて渡す
- Artifact に画像を同梱するなら `files` に `img/<name>.png` -> ローカルパスの対応で渡す (6 ファイル程度なら 1 回で publish できる)
- 公式 Icon package の zip を手で展開すると、`__MACOSX` や `.DS_Store`、環境によっては空のフォルダが混ざる。`fetch_icons.sh` は SVG だけを取り出すので影響しない

## アイコンの出所

- mingrammer/diagrams (GitHub) の PNG は公式デザインの再配布で、急場しのぎには使えるが PNG で版も古い。公式パッケージが手に入ったら SVG に差し替える
- 公式パッケージは aws.amazon.com/architecture/icons の Asset Package zip (約 14MB)。リリースごとに URL が変わる。`fetch_icons.sh` は 2026-07-31 版の URL と SHA-256 を固定している。新しい版はそのページで zip の URL を確認し、`AWS_ICONS_URL` / `AWS_ICONS_VERSION` / `AWS_ICONS_SHA256` を渡して取得する (SHA-256 は一度取得して確認した値を使う)
- アイコンは再配布しない。スキルのリポジトリ (公開) には入れず、使う人がそれぞれ公式から取得する
