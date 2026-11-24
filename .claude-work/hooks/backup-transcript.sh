#!/usr/bin/env bash
set -u

INPUT="$(cat)"

REPORTS_DIR="${DAILY_REPORT_DIR:-$HOME/.claude-work/reports}"
REPORTS_DIR="${REPORTS_DIR/#\~/$HOME}"

LOG="$REPORTS_DIR/.hook.log"
mkdir -p "$REPORTS_DIR" 2>/dev/null

log() { printf '%s [backup-transcript] %s\n' "$(date +%FT%T)" "$*" >> "$LOG" 2>/dev/null; }

if ! command -v jq >/dev/null 2>&1; then
  log "jq not found, skipping"
  exit 0
fi

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

[ -z "$SESSION_ID" ]      && { log "missing session_id";      exit 0; }
[ -z "$TRANSCRIPT_PATH" ] && { log "missing transcript_path"; exit 0; }
[ -f "$TRANSCRIPT_PATH" ] || { log "transcript not found: $TRANSCRIPT_PATH"; exit 0; }

TODAY=$(date +%Y-%m-%d)
DEST_DIR="$REPORTS_DIR/$TODAY/transcripts"
DEST="$DEST_DIR/$SESSION_ID.jsonl"

mkdir -p "$DEST_DIR" 2>/dev/null || { log "mkdir failed: $DEST_DIR"; exit 0; }

TMP="$DEST.tmp.$$"
if cp -f "$TRANSCRIPT_PATH" "$TMP" 2>>"$LOG"; then
  mv -f "$TMP" "$DEST" 2>>"$LOG" || { rm -f "$TMP" 2>/dev/null; log "mv failed"; exit 0; }
else
  rm -f "$TMP" 2>/dev/null
  log "cp failed"
fi

exit 0
