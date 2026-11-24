#!/usr/bin/env python3
"""Claude Code PreToolUse hook (matcher: Bash)

origin (リモート) への書き込みを伴うコマンドをブロックする。
レビュー専用クローンで push / MR 更新を絶対に発生させないためのガード。

exit 2 = ツール実行をブロックし、stderr の内容を Claude にフィードバックする。

使い方:
  deny-origin-write.py
      常に有効。プロジェクトの .claude/settings.local.json から参照する場合。
  deny-origin-write.py --only-under ~/review
      cwd が指定パス配下のときだけ有効。プロファイル共通設定
      (~/.claude-work/settings.json) に置いて、レビュー用クローン置き場だけを
      対象にする場合。
"""

import json
import os
import re
import sys

# 読み取り専用として許可する glab のサブコマンド (group -> {sub, ...})
GLAB_READONLY = {
    "mr": {"list", "view", "diff", "checkout"},
    "issue": {"list", "view"},
    "ci": {"list", "view", "status", "trace", "get"},
    "repo": {"view", "clone", "list", "contributors"},
    "release": {"list", "view"},
    "label": {"list"},
    "milestone": {"list"},
    "auth": {"status"},
}

# サブコマンドなしで許可するもの
GLAB_BARE_OK = {"", "version", "help", "completion"}

# HTTP メソッド指定フラグ。curl の -x (proxy) と区別するため大文字小文字は区別する
METHOD_FLAG = re.compile(r"(?:^|\s)(?:-X|--request|--method)[\s=]*([A-Za-z]+)")

# glab api でデータを送る = 書き込み
GLAB_DATA_FLAGS = re.compile(
    r"(?:^|\s)(?:--data\b|--data-\w+\b|-d\b|--field\b|-F\b|-f\b|--raw-field\b|--input\b)"
)

# curl / wget でデータを送る = 書き込み (-f は curl の --fail なので除外)
HTTP_DATA_FLAGS = re.compile(
    r"(?:^|\s)(?:--data\b|--data-\w+\b|-d\b|--form\b|-F\b|--upload-file\b|-T\b"
    r"|--post-data\b|--post-file\b|--body\b)"
)


def block(msg):
    print(
        "[deny-origin-write] {}\n"
        "このクローンはレビュー専用で、origin への書き込みは全面禁止されています。".format(msg),
        file=sys.stderr,
    )
    sys.exit(2)


def check_git(seg):
    if not re.search(r"(?:^|[\s\"'(=/])git\b", seg, re.I):
        return
    if re.search(r"\b(?:push|send-pack)\b", seg, re.I):
        block("git push / send-pack は禁止")
    if re.search(r"\bremote\b\s+(?:set-url|add|rename|remove|rm|prune|set-branches|set-head)\b", seg, re.I):
        block("git remote の変更は禁止 (push ガードの無効化になる)")
    if re.search(r"\bconfig\b.*\bremote\.", seg, re.I):
        block("git config remote.* の変更は禁止 (push ガードの無効化になる)")
    if re.search(r"\bsubtree\b.*\bpush\b|\bsvn\b\s+dcommit\b", seg, re.I):
        block("リモートへの反映を伴う git サブコマンドは禁止")


def check_glab(seg):
    m = re.search(r"(?:^|[\s\"'(=/])glab\b(.*)$", seg, re.I)
    if not m:
        return
    rest = m.group(1)
    tokens = [t.lower() for t in re.findall(r"[^\s\"']+", rest) if not t.startswith("-")]
    group = tokens[0] if tokens else ""
    sub = tokens[1] if len(tokens) > 1 else ""

    if group in GLAB_BARE_OK:
        return

    if group == "api":
        method = METHOD_FLAG.search(rest)
        if method and method.group(1).upper() not in ("GET", "HEAD"):
            block("glab api の {} リクエストは禁止".format(method.group(1).upper()))
        if GLAB_DATA_FLAGS.search(rest):
            block("glab api のデータ送信フラグ付き実行は禁止")
        return

    if sub in GLAB_READONLY.get(group, set()):
        return

    block("glab {} {} は書き込みの可能性があるため禁止".format(group, sub).rstrip())


def check_http(seg):
    if not re.search(r"(?:^|[\s\"'(=/])(?:curl|wget|xh|https?)\b", seg, re.I):
        return
    if not re.search(r"gitlab\.[\w.-]+|/api/v4/", seg, re.I):
        return
    method = METHOD_FLAG.search(seg)
    if method and method.group(1).upper() not in ("GET", "HEAD"):
        block("GitLab API への {} リクエストは禁止".format(method.group(1).upper()))
    if HTTP_DATA_FLAGS.search(seg):
        block("GitLab API へのデータ送信は禁止")


# 引数を出力・検索するだけでプログラムを起動しないコマンド。
# echo "git push" のような文字列を誤検知しないための除外リスト。
TEXT_ONLY_HEADS = {
    "echo", "printf", "cat", "bat", "grep", "egrep", "fgrep", "rg", "jq",
    "head", "tail", "wc", "sort", "uniq", "comm", "column", "tr", "cut",
    "diff", "tee", "true", "false", "test",
    # 実体を起動せずパスを引くだけのもの
    "which", "type", "hash", "whereis",
}

# リダイレクト (>file, 2>&1, <file, &>file) を落とすためのパターン
REDIRECT = re.compile(r"(?:^|\s)\d*(?:&?>>?|<)\s*&?\s*\S+")


def strip_redirects(seg):
    return REDIRECT.sub(" ", seg).strip()


def is_text_only(seg):
    """セグメントの先頭コマンドが「文字列を扱うだけ」のものかを判定する。"""
    if seg.startswith("#"):
        return True
    toks = [
        t for t in re.findall(r"[^\s]+", seg)
        # 先頭の環境変数代入 (FOO=bar cmd ...) は読み飛ばす
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", t)
    ]
    if not toks:
        return False
    head = toks[0].strip("\"'").rsplit("/", 1)[-1].lower()
    if head in TEXT_ONLY_HEADS:
        return True
    # command -v foo / command -V foo は foo を起動しない
    if head == "command" and len(toks) > 1 and toks[1] in ("-v", "-V"):
        return True
    return False


def in_scope(payload):
    """--only-under が指定されていれば cwd がその配下かを判定する。

    引数不備や cwd 不明のときはガードを有効のまま扱う (fail-closed)。
    """
    if "--only-under" not in sys.argv:
        return True
    idx = sys.argv.index("--only-under")
    if idx + 1 >= len(sys.argv):
        return True
    root = os.path.realpath(os.path.expanduser(sys.argv[idx + 1]))
    cwd = payload.get("cwd") or os.getcwd()
    cwd = os.path.realpath(os.path.expanduser(cwd))
    return cwd == root or cwd.startswith(root + os.sep)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if not in_scope(payload):
        sys.exit(0)

    cmd = (payload.get("tool_input") or {}).get("command") or ""
    if not cmd.strip():
        sys.exit(0)

    # 行継続・連続空白を潰してから単純コマンド単位に分割する
    norm = re.sub(r"\\\n", " ", cmd)
    norm = re.sub(r"\s+", " ", norm)

    for seg in re.split(r"[;\n]|&&|\|\||\||&", norm):
        seg = seg.strip()
        if not seg or is_text_only(seg):
            continue
        seg = strip_redirects(seg)
        check_git(seg)
        check_glab(seg)
        check_http(seg)

    sys.exit(0)


if __name__ == "__main__":
    main()
