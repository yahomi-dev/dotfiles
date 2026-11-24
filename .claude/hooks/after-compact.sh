#!/bin/sh
# Claude Code SessionStart hook (matcher: compact)
# 会話圧縮の直後に一度だけ復旧指示を additionalContext で注入する。
# 圧縮サマリーは仮説として扱わせ、plan ファイルと状態ファイルを正とさせる。
# fail-open: どんな場合も exit 0 で Claude Code 本体を止めない。

input=$(cat)
cwd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
state_file="${cwd}/.claude-session-state.md"

if [ -f "$state_file" ]; then
	state_note="状態ファイル ${state_file} が存在する。必ず Read で読み直すこと。"
else
	state_note="状態ファイル ${state_file} は存在しない。以後、方針の採用・却下やフェーズ進行があればこのファイルを作成して記録すること。"
fi

context="直前に会話が圧縮された。圧縮サマリーは仮説として扱い、作業再開前に次を行うこと。
1) plan ファイルがあれば読み直す。
2) ${state_note}
3) TaskList を確認する。
4) plan mode 中だったなら再突入する。
却下済みの案を再実装しない。状態ファイルに書かれたフェーズの順序制約と禁止事項を守る。サマリーと状態ファイルが食い違う場合は状態ファイルを正とする。"

printf '%s' "$context" | python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}, ensure_ascii=False))' 2>/dev/null
exit 0
