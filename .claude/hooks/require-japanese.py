#!/usr/bin/env python3
# Stop フック: 最後の応答に日本語がほとんど含まれていなければ、停止を止めて日本語で書き直させる。
# 判定はコードブロック、インラインコード、URL を除いた本文で、かな・漢字の数と英字の数の比で行う。
import json
import re
import sys

MIN_CHARS = 40
MIN_JAPANESE_RATIO = 0.2

JAPANESE = re.compile(r"[぀-ヿ㐀-䶿一-鿿]")
LATIN = re.compile(r"[A-Za-z]")
STRIP = [
    re.compile(r"```.*?```", re.S),
    re.compile(r"`[^`\n]*`"),
    re.compile(r"https?://\S+"),
]


def last_assistant_text(transcript_path: str) -> str:
    text = ""
    with open(transcript_path, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("type") != "assistant":
                continue
            content = entry.get("message", {}).get("content", [])
            if not isinstance(content, list):
                continue
            parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
            joined = "\n".join(p for p in parts if p.strip())
            if joined:
                text = joined
    return text


def main() -> None:
    payload = json.load(sys.stdin)
    # 書き直しの後にもう一度止めると抜けられなくなるので、2 回目は通す
    if payload.get("stop_hook_active"):
        return
    path = payload.get("transcript_path")
    if not path:
        return
    text = last_assistant_text(path)
    for pattern in STRIP:
        text = pattern.sub(" ", text)
    japanese = len(JAPANESE.findall(text))
    latin = len(LATIN.findall(text))
    if japanese + latin < MIN_CHARS:
        return
    if japanese / (japanese + latin) >= MIN_JAPANESE_RATIO:
        return
    print(json.dumps({
        "decision": "block",
        "reason": "直前の応答が日本語になっていません。ユーザへの受け答えは日本語で行う決まりです (CLAUDE.md)。同じ内容を日本語で書き直してください。",
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
