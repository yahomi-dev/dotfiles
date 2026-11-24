#!/bin/bash
# GitLab project uploads へ png 画像のみをアップロードする Claude Code 用ラッパ。
# 許可範囲を「png の multipart POST」に限定するのが目的 (settings.json の allow と対)。
# トークンは glab の設定から内部で解決し、標準出力には markdown のみを出す。
set -eu

# URL (https://host/... / ssh://git@host:22/... / git@host:group/...) からホスト名だけを取り出す
host_of() {
	url="${1#*://}"
	url="${url#*@}"
	url="${url%%/*}"
	printf '%s' "${url%%:*}"
}

# ホストは GITLAB_HOST (glab と同じ環境変数) を優先し、無ければカレントのリポジトリの origin から決める
HOST="$(host_of "${GITLAB_HOST:-$(git remote get-url origin 2>/dev/null || true)}")"
[ -n "$HOST" ] || { echo "GitLab のホストが決められません。GITLAB_HOST を設定するか、origin のあるリポジトリで実行してください" >&2; exit 1; }
project="${1:?usage: glab-upload-png.sh <project-path> <file.png>...}"
shift

token="$(glab config get token --host "$HOST" 2>/dev/null || true)"
if [ -z "$token" ]; then
	# フォールバック: glab が git の credential helper として構成済みならそこから解決
	token="$(printf "protocol=https\nhost=%s\n\n" "$HOST" | git credential fill 2>/dev/null | awk -F= '/^password=/{print $2; exit}')"
fi
[ -n "$token" ] || { echo "glab token が取得できません" >&2; exit 1; }

encoded=$(printf %s "$project" | sed 's|/|%2F|g')

for f in "$@"; do
	case "$f" in
	*.png) ;;
	*)
		echo "png 以外は拒否: $f" >&2
		exit 1
		;;
	esac

	magic=$(od -An -N8 -tx1 "$f" | tr -d ' \n')
	[ "$magic" = "89504e470d0a1a0a" ] || {
		echo "PNG マジックバイト不一致: $f" >&2
		exit 1
	}

	curl -sS --fail --header "Authorization: Bearer $token" --form "file=@$f;type=image/png" \
		"https://$HOST/api/v4/projects/$encoded/uploads" |
		grep -oP '"markdown":"\K[^"]+'
done
