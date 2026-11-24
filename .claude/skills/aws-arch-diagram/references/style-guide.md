# 描画規約とレイアウトの型

draw.io の「AWS 2024 / AWS Architecture Icons」で描いたときの見た目に寄せる。座標は viewBox 単位 (= CSS px)。

## 簡易版 (icon-first)

目的: 読者がアイコンだけで流れを追える。文字はサービス名 + 1 行の補足 (ドメイン、バケットの役割) まで。

- キャンバス: 白無地 (グリッド無し)、viewBox 幅 1400。高さは内容に合わせる
- サービスアイコン **64px**。ラベルは `label2(cx, icon_bottom + 16, "Amazon CloudFront", "www.example.com")` (1 行目 12.5px / 500、2 行目 10.5px 灰)
- 補助のリソースアイコン (CloudFront Functions、アクセスキー) は **56px**、ラベルはアイコンの右か下
- 1 スタック = `sbox(x, y, 600, 240, "SiteProduction")` の青破線枠。中は 2 行 2 列のグリッド:
  - 上段: 左 Functions (x+44, y+36)、右 S3 assets (x+480, y+32)
  - 下段: 左 CloudFront (x+40, y+134)、右 S3 site (x+480, y+134)
  - Functions -> CloudFront は縦の破線 (矢尻なし)。CloudFront -> S3 は横の実線、2 本目は x+292 で折って上段へ
- 左 180px は利用者 (枠外)、180..380 は Route 53 / ACM (枠内)、380.. がスタック枠。右端 1040..1340 に IAM (CiAccess) の枠
- 利用者: `users` アイコン (36, 176)。HTTPS は `(100, 212) -> 入口の CloudFront 左辺 (cy-?)`、名前解決は `(100,196)->(130,196)->(130,92)->Route 53 左辺`
- Route 53 / ACM から複数の CloudFront へは、縦の幹 (`arrow=False`) を 1 本引いて枝を出す。幹の x は Route 53 = 360、ACM = 330 のように 30px ずらす
- AWS Cloud 枠: `cloud_frame(180, 20, 1200, H, "アカウント ...")`。見出し行の下に **40px** 空けてから中身 (`<g transform="translate(0 40)">` で中身をまとめて下げると座標を触らずに済む)
- 線: `.sedge` 1.8px 黒 (#232F3E)、矢尻 6px。ラベル `.slbl` 10.5px 灰、白のふち取り (paint-order: stroke) で線の上に置ける

## 詳細版 (設定値まで)

目的: レビューと引き継ぎ。1 スタック = 1 本の帯で、左から Function -> Distribution -> バケットの順に流れを置き、各ノードの下 / 右に設定値を 10px で列挙する。

- キャンバス: グリッド (`fill="url(#grid2)"`、20px / 100px の薄い線)。viewBox 幅 1440〜1600
- AWS Cloud 枠 (`cloud_frame`) -> 手動管理の global 帯 (`manual_box`、Route 53 / ACM) -> Region 枠 (`region_frame`) -> Region 内の手動管理帯 (SSM / bootstrap) -> スタック帯 (`stack_band(60, y0, 1320, 190, name, "Environment=...")`) を縦に並べる。帯の間は 16px
- 帯の中: Function アイコン 36px (300, y0+42) + 説明 `lines(80, y0+52, ...)`。Distribution 56px (380, y0+32) + 説明 `lines(380, y0+104, ..., 13)`。バケット 40px (830, y0+40 / y0+110) + 説明 `lines(880, y0+56 / y0+126, ...)`
- 線: `.edge` 1.3px 灰 (#545B64)、矢尻 7px。2 本目は説明文の右 (x=760) を縦に通す
- 利用者を追加するときは枠の外 (左) に置き、中身全体を `translate(160 0)` で右へずらす。線は枠の上の隙間 (手動管理帯とスタック帯の間、y=280 前後) を通して Distribution の上辺に入れる。利用者の要素は `</g>` の後に描く (先に描くと枠の塗りに隠れる)
- IAM は最下段の帯に、ユーザごとのカード (`.card`、幅 370〜405) を横に並べる

## 文字クラス

| クラス | 用途 | サイズ |
|---|---|---|
| `tb` | 見出し (太字) | 12px |
| `t` | 本文 | 12px |
| `ts` | 補足 (灰) | 10px |
| `tm` / `tm9` | 等幅 (名前、ARN、パス) | 10.5px / 9.5px |
| `te` | 枠のタグ (灰、字間広め) | 9.5px |
| `lbl` / `slbl` | 線のラベル (白ふち) | 10px / 10.5px |
| `sl` / `sls` | 簡易版のラベル 1 行目 / 2 行目 | 12.5px / 10.5px |
| `stag` | 簡易版の枠名 (青) | 11px |

文字幅の目安: 英数は font-size x 0.55、日本語は font-size x 1.0。枠に収まるかはこれで見積もり、PNG で確認する。

## 色 (公式のカテゴリ色)

- AWS Cloud 枠 #232F3E、Region #00A4A6、簡易版の枠 #1E88A8、手動管理 / スタック帯の線 #7D8998
- アイコン自体は公式 SVG の色をそのまま使う (Networking 紫 #8C4FFF、Storage 緑 #7AA116、Security 赤 #DD344C、Management 桃 #E7157B)。図の中で独自の色を追加しない

## アイコンの選び方

- **サービス** (Arch_*_64.svg、塗りの四角): 「このサービスを使っている」を示す。基本はこれ
- **リソース** (Res_*_48.svg、線画): サービスの中の個別の物 (Bucket、Function、Stack、Parameter、アクセスキー)。公式にリソースアイコンしか無い概念はこれを使う
- **グループ** (Architecture-Group-Icons、*_32.svg): 枠の左上の小アイコン (AWS Cloud、Region、VPC、Subnet など)
- **一般** (Res_General-Icons/Res_48_Light): Users / User / Client / Internet / Mobile client。利用者には Users
- 検索: `scripts/find_icon.sh lambda` のようにキーワードで。見つけたファイル名を `register("lambda", "Arch_AWS-Lambda_64.svg")` で登録する
