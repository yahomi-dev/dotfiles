---
type: llm
focus: trace
weight: 1
---

node tools/render.mjs sheet (または scene / stills) で out/ に画像が生成され、エージェントがその画像を Read で開いて確認し、必要なら timeline.js を直してから書き出しに進んでいる。ffmpeg が使える環境では out/*.mp4 が 1920x1080 / 30fps で生成されている。
