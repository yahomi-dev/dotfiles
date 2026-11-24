#!/bin/sh
# Claude Code PreToolUse hook (matcher: Bash)
# AI トレーラー付きの git commit を拒否する (ユーザ方針:
# Co-Authored-By: Claude / Generated with Claude Code 系フッターを付けない)。
# exit 2 = ツール実行をブロックし、stderr を Claude へフィードバックする。

input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)

case "$cmd" in
*git*commit*)
	if printf '%s' "$cmd" | grep -qiE 'co-authored-by:.*claude|generated with.*claude'; then
		echo "AI トレーラー (Co-Authored-By: Claude / Generated with Claude Code) は禁止。メッセージから除去して再実行すること" >&2
		exit 2
	fi
	;;
esac
exit 0
