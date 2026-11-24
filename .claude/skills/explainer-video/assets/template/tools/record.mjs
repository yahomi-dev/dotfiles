// record.mjs — 実物を 1 回流した記録 (JSON) を data.js (window.RECORD) に変換する
//   node tools/record.mjs record.json [data.js]
// 動画に出す数字・文はすべて RECORD から取るので、アプリ側を直したら JSON を取り直してこれを流し直せば字幕も変わる
import fs from 'node:fs';
import path from 'node:path';

const [src, dst = 'data.js'] = process.argv.slice(2);
if (!src) throw new Error('usage: node tools/record.mjs <record.json> [data.js]');
const json = JSON.parse(fs.readFileSync(src, 'utf8'));
const body = `// data.js — 実物を 1 回流した記録。${path.basename(src)} から tools/record.mjs で生成 (手で直さず、元の JSON を直して作り直す)\nwindow.RECORD = ${JSON.stringify(json, null, 2)};\n`;
fs.writeFileSync(dst, body);
console.log(`${dst} <- ${src}`);
