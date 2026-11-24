---
name: aws-arch-diagram
description: AWS の構成図 (アーキテクチャ図 / インフラ構成図 / システム構成図 / クラウド構成図) を、CDK / CloudFormation / Terraform などの IaC や AWS CLI の実態から起こし、AWS 公式アイコンで draw.io 風の HTML / PNG / SVG として生成する。「構成図を描いて」「インフラ図が欲しい」「AWS の全体像を図にして」「アーキテクチャ図を資料に貼りたい」「S3 と CloudFront の関係を図で」など、クラウド構成を図にする依頼があれば、ツールや形式の指定が無くても必ずこの skill を使う。公式アイコンの検索、draw.io 風の描画規約、簡易版 / 詳細版の 2 段構え、画像書き出し、Artifact が開けない環境での渡し方までを含む。
effort: high
---

# AWS 構成図 (aws-arch-diagram)

IaC の実態を AWS 公式アイコンの draw.io 風 SVG に起こし、HTML ページ + 図ごとの PNG / SVG として渡す。
図は Python スクリプト (座標直書き) から生成し、手で SVG を触らない。更新は常にスクリプトを修正して再生成する。

## 成果物の形

- **HTML ページ 1 枚** (ライト固定、`<title>` + `<style>` + `<main>` のみで Artifact にそのまま出せる形)。中に図を複数枚:
  - **簡易版**: アイコン + サービス名 + 1 行の補足だけ。読者が 10 秒で全体像を掴む用。環境が複数あるなら「production のみ」と「全環境」の 2 枚にすると資料で使い分けられる
  - **詳細版**: スタック / リソースごとの帯に設定値 (バケット名、キャッシュポリシー、IAM の権限など) まで書く。レビューや引き継ぎ用
- **図ごとの PNG (2 倍解像度) と SVG** を `img/` に置き、ページから「画像: PNG / SVG」でリンクする
- **渡し方はローカルファイルが正**。利用者の `Downloads/<project>-infra-diagram/` (HTML + `img/`) と作業用のディレクトリ (例: `~/tmp/<project>/`) に置く。読み手のネットワークから claude.ai に接続できないことがあるので、Artifact は参照用に publish するだけに留める

## 初めて使うとき (前提)

- Python 3.9 以上 (標準ライブラリだけで動く)、curl、headless で動く Chromium (playwright が取得したもの `~/.cache/ms-playwright/chromium-*/` か、`CHROME=/path/to/chrome`)
- 公式アイコンはこのスキルに同梱しない (AWS Architecture Icons の再配布になるため)。最初に `scripts/fetch_icons.sh` を 1 回実行し、公式の Asset Package (固定の版、SHA-256 を確認する) を `${XDG_CACHE_HOME:-~/.cache}/aws-architecture-icons/` に展開する。保存先は `AWS_ICONS_DIR` で変えられる (awsdiag.py と find_icon.sh も同じ変数を見る)
- 実例を一度動かすと全体像がつかめる:

```sh
S=~/.claude/skills/aws-arch-diagram
bash $S/scripts/fetch_icons.sh
python3 -I $S/references/example-static-site.py /tmp/aws-diagram-example
bash $S/scripts/render_png.sh /tmp/aws-diagram-example/export
```

## 手順

1. **実態を集める。推測で描かない。** CDK なら `infra/src/*.ts` と `cdk.out/*.template.json` の `Resources` (型と論理 ID の一覧が取れる)。Terraform なら plan / state。IaC 外で手動管理しているもの (DNS レコード、ACM 証明書、SSM パラメータ、CDK bootstrap、手動発行のアクセスキー) も README / runbook / コメントから拾い、図では「手動管理 (IaC 外)」の枠に分けて置く。
2. **載せる範囲を決める。** 既定は **AWS リソースだけ** (利用者、CI パイプライン、SaaS、別システムの EC2 は入れない)。利用者やレビュー担当などの actor は、ユーザが求めたものだけ加える。同じアカウントに他システムがあっても脚注で触れるに留める。
3. **スクリプトを書く。** `references/example-static-site.py` を出力先 (例: `~/tmp/<project>/infra-diagram.build.py`) へコピーし、データと座標を書き換える。ヘルパは `scripts/awsdiag.py` (下の API 一覧)。スクリプトはヘルパを `AWS_ARCH_DIAGRAM_DIR` (既定は `~/.claude/skills/aws-arch-diagram`) から読む。使うアイコンが登録済みの 15 個に無ければ `scripts/find_icon.sh <keyword>` で公式パッケージから探し、`awsdiag.register("key", "ファイル名")` で追加する。
4. **ビルドして 1 回だけ見る。** `python3 -I <script> <out>` -> `scripts/render_png.sh <out>/export` -> PNG を Read で見て、ラベルの重なり・枠線との干渉・はみ出しを修正する。修正したらもう 1 回だけ見る。
5. **配布する。** HTML と `img/` (PNG / SVG) を所定の場所へコピー。Artifact に出すなら `files` で `img/*` も一緒に publish する。
6. **記録する。** スクリプトの保存先と「何を載せない判断をしたか」をメモリに残す (次回の更新で同じ議論を繰り返さないため)。

## 描画の約束 (詳細と座標の型は references/style-guide.md)

- **アイコンは公式 Icon package の SVG のみ。** fx マークや雲を手描きしない。公式に無い概念 (例: 独自の SaaS) は文字だけの枠にする
- **サービスアイコン (塗りの四角) を基本**にする。リソースアイコン (線画) は「個別リソースを区別したい」時だけ。S3 は複数バケットを描く場合も塗り (利用者と比較して決めた)。CloudFront Functions、アクセスキー、Parameter Store、Stack は公式がリソースアイコンしか無いので線画
- **線種**: 実線 = 実際に流れるリクエストと書き込み (HTTPS、名前解決、s3 sync)。破線 = 設定の紐付け (ALIAS、証明書、cdk diff)。名前解決はリゾルバの実リクエストなので実線
- **利用者は AWS Cloud の枠外の左**に置き、production の入口へ実線 HTTPS、Route 53 へ実線 名前解決を引く。IP 制限のある環境には一般利用者の線を引かない (誤解を生む)
- **グループ枠**: AWS Cloud = 黒実線 + 雲アイコン、Region = 青緑の破線 + 旗、スタック = 簡易版は青破線 + Stack アイコン、詳細版は灰実線の白帯、手動管理 = 薄い塗り + 灰破線
- **線は直角**、交差は最小限。分岐は縦の幹 (矢尻なし) から枝 (矢尻あり) を出す。ラベルは線の上に短く (`default` / `/files/*` / `ALIAS`)
- **余白**: 枠の見出し (AWS Cloud など) と内側の枠の間は 40px 以上。ラベルが枠線に乗らない位置にアイコンを置く (枠の左端からアイコン中心まで 90px 以上)
- 文言は半角括弧、`・` 区切り。日本語フォントは IBM Plex Sans JP (Google Fonts)、等幅は IBM Plex Mono

## awsdiag.py の API

| 関数 | 用途 |
|---|---|
| `use(key, x, y, size, cls=None)` | アイコン配置 (左上座標、一辺) |
| `text(x, y, s, cls="t", anchor=None)` / `lines(x, y0, [(cls, s)], step)` | 文字。cls は style-guide の表 |
| `label2(cx, y, main, sub)` | 簡易版のアイコン下 2 行ラベル (中央寄せ) |
| `edge(points, style="s"\|"d", dashed=False, arrow=True)` | 直角の線。s = 簡易版 (太・黒)、d = 詳細版 (細・灰) |
| `cloud_frame` / `region_frame` / `manual_box` / `stack_band` / `sbox` | グループ枠 (公式表記) |
| `page(title, eyebrow, h1, lead, figures, notes)` | HTML ページ。figures は `{num, heading, svg, caption, img}` |
| `export_figures(out_dir, {name: svg})` | 図ごとの standalone HTML (PNG 用) と SVG |
| `register(key, filename, size=None)` | 公式パッケージのアイコンを追加 |

アイコン・矢尻・グリッドの `<defs>` はページ先頭の非表示 svg に 1 回だけ置き、全図が `<use href="#ic-...">` で参照する (同じアイコンを図ごとに埋め込まない)。

## 落とし穴

`references/pitfalls.md` を読む。headless Chromium の起動方法、`.size` の `read` が `&&` で止まる件、Google Fonts の読み込み待ち、Artifact の制約 (ダウンロード不可、ネットワークによっては開けない) など、1 度ずつ踏んだものをまとめてある。

## ファイル

- `scripts/awsdiag.py` ヘルパ本体。`scripts/render_png.sh <export_dir>` PNG 化。`scripts/find_icon.sh <keyword>` 公式アイコン検索。`scripts/fetch_icons.sh` 公式アイコンの取得
- 公式 Icon package (取得するもの、スキルの外): `${AWS_ICONS_DIR:-~/.cache/aws-architecture-icons}/Icon-package_<版>/`。`fetch_icons.sh` の既定は 2026-07-31 版 (SVG 1852 個、aws.amazon.com/architecture/icons の Asset Package)。新版が出たら URL と SHA-256 を `fetch_icons.sh` に渡して隣に展開する。`awsdiag.OFFICIAL_PACKAGE_DIR` 配下を rglob で探すので置くだけでよい
- 登録済みのアイコン 15 個 (`awsdiag.ICONS`): Route 53 / ACM / CloudFront / S3 / IAM / CloudFormation / Systems Manager の各サービス、S3 Bucket / CloudFront Functions / アクセスキー / Stack / Parameter Store の各リソース、AWS Cloud / Region のグループ、Users。`assets/icons/` に SVG を置くと公式パッケージより先に使う (任意。公式のアイコンのコピーなので git に入れない)
- `references/style-guide.md` レイアウトの型 (座標・サイズ・色・クラス)
- `references/pitfalls.md` 落とし穴
- `references/example-static-site.py` 実例 (架空の静的サイト、3 図、CDK 4 スタック)。新しい図はこれをコピーして始める
