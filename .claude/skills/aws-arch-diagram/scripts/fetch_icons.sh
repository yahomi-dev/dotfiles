#!/usr/bin/env bash
# AWS 公式の Architecture Icons (Asset Package の zip) を取得し、SVG だけをキャッシュのディレクトリに展開する。
# usage: fetch_icons.sh   (展開済みなら何もしない)
# 保存先: AWS_ICONS_DIR (既定は ${XDG_CACHE_HOME:-~/.cache}/aws-architecture-icons) の下の Icon-package_<版>/。awsdiag.py と find_icon.sh も同じ場所を見る
# 取得元: https://aws.amazon.com/architecture/icons/ の Asset Package。固定する版は下の VERSION / URL / SHA256 (2026-07-31 版)
#   新しい版を使うときは、そのページの zip の URL を AWS_ICONS_URL に、版 (MMDDYYYY) を AWS_ICONS_VERSION に、zip の SHA-256 を AWS_ICONS_SHA256 に渡す (3 つを揃える)
#   SHA-256 は 16 進 (sha256sum の出力) か、SRI 形式 (sha256-<base64>) で書く。既定の値は SRI 形式
# アイコンの利用条件は取得元のページに従う。アイコンのファイルはスキルのリポジトリに入れない (再配布になるため)
# 必要なもの: curl、python3 (SHA-256 の確認と zip の展開に標準ライブラリを使う)
set -euo pipefail

VERSION="${AWS_ICONS_VERSION:-07312026}"
URL="${AWS_ICONS_URL:-https://d1.awsstatic.com/onedam/marketing-channels/website/public/shared/architecture-icon-release/Icon-package_07312026.5846e92413caa21490223536cc97f1269e44fa92.zip}"
SHA256="${AWS_ICONS_SHA256:-sha256-0tFmxFNSZHF0nVIODbAixFmr73WdKUbPLdHRyZLcZSY=}"
root="${AWS_ICONS_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/aws-architecture-icons}"
dest="$root/Icon-package_$VERSION"

if [ -f "$dest/.complete" ]; then
  echo "展開済み: $dest"
  exit 0
fi

mkdir -p "$root"
work="$(mktemp -d "$root/.fetch-XXXXXX")"
trap 'rm -rf "$work"' EXIT

echo "取得: $URL" >&2
curl -fsSL --retry 2 -o "$work/package.zip" "$URL"

# SHA-256 を確認してから、SVG だけを取り出す (PNG、__MACOSX、.DS_Store などは捨てる)。zip の外へ書くパスは拒否する
python3 -I - "$work/package.zip" "$work/out" "$SHA256" <<'PY'
import base64
import hashlib
import pathlib
import sys
import zipfile

src = sys.argv[1]
out = pathlib.Path(sys.argv[2]).resolve()
expected = sys.argv[3].strip()
digest = hashlib.sha256(pathlib.Path(src).read_bytes()).digest()
actual = "sha256-" + base64.b64encode(digest).decode() if expected.startswith("sha256-") else digest.hex()

if actual != expected.lower() and actual != expected:
    raise SystemExit(f"zip の SHA-256 が合わない (期待 {expected}、実際 {actual})。URL か版が変わった可能性がある。取得元のページで確認する")

count = 0

with zipfile.ZipFile(src) as z:
    for info in z.infolist():
        name = info.filename
        base = name.rsplit("/", 1)[-1]

        if info.is_dir() or not name.lower().endswith(".svg") or name.startswith("__MACOSX/") or base.startswith("."):
            continue

        target = (out / name).resolve()

        if not target.is_relative_to(out):
            raise SystemExit(f"zip の外を指すパスがある: {name}")

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(z.read(info))
        count += 1

print(f"SHA-256 を確認し、SVG {count} 個を展開した")
PY

rm -rf "$dest"
mv "$work/out" "$dest"
touch "$dest/.complete"
echo "展開先: $dest"
