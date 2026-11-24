#!/bin/sh
# iTerm2 の Claude Code 状態表示 (Mac 専用)。
# バイナリが無い環境 (WSL など) では何もせずに終わる。stdin の JSON はそのまま渡す。
BIN="$HOME/.config/iterm2/cc-status"
[ -x "$BIN" ] || exit 0
exec "$BIN" "$@"
