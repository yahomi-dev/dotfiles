---
type: llm
focus: trace
weight: 1
---

./chat-video にテンプレートがコピーされ、record.json から data.js が作られ、timeline.js が 操作 (チャットに質問を打って送る、カーソルとズームあり) -> 仕組み (規約検索 -> AI の返事 -> 禁止語チェック) -> 構成図 (サーバー / AI / 規約 DB) -> 操作 (返事が出る) -> 締め の順で、文言と数字が record.json と一致し、コンタクトシートで確認したうえで (ffmpeg があれば) MP4 が書き出されている。
