#!/usr/bin/env node
// render.sh が描いた SVG を 1 ページに並べた HTML を作る。ページの題、冒頭の説明、図の並びは作業ディレクトリの page.json に書く
//   node build-html.mjs [<作業ディレクトリ>]            -> data-model-diagrams.html (スタンドアロン。各図を PNG / SVG で保存するボタン付き。ブラウザで開くだけで使える)
//   node build-html.mjs [<作業ディレクトリ>] --artifact -> page.html (claude.ai の artifact 用。artifact の中ではダウンロードが動かないのでボタン無し)
// page.json: { "title": "...", "leads": ["HTML", ...], "sections": [{ "id", "heading", "note" (HTML), "file" (拡張子なしの SVG の名前), "nav" (省略するとナビに出さない) }] }
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const args = process.argv.slice(2);
const artifact = args.includes("--artifact");
const dir = args.find((a) => !a.startsWith("--")) ?? ".";
const tools = !artifact;
const outName = artifact ? "page.html" : "data-model-diagrams.html";

const escapeHtml = (s) => {
	return s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
};

const page = JSON.parse(readFileSync(join(dir, "page.json"), "utf8"));
const saveButtonsJs = readFileSync(join(dirname(fileURLToPath(import.meta.url)), "save-buttons.js"), "utf8");

const head = `<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${escapeHtml(page.title)}</title>
<style>
:root { --bg: #f6f5f2; --fg: #1f2328; --muted: #59636e; --card: #ffffff; --border: #d8d6d0; --accent: #0969da; color-scheme: light }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg: #16181c; --fg: #e6e6e6; --muted: #9aa0a6; --card: #ffffff; --border: #3a3d42; --accent: #6cb6ff; color-scheme: dark } }
:root[data-theme="dark"] { --bg: #16181c; --fg: #e6e6e6; --muted: #9aa0a6; --card: #ffffff; --border: #3a3d42; --accent: #6cb6ff; color-scheme: dark }
html { padding-top: env(safe-area-inset-top, 0px); padding-bottom: env(safe-area-inset-bottom, 0px) }
body { margin: 0; background: var(--bg); color: var(--fg); font-family: "Noto Sans JP", system-ui, sans-serif; font-size: 14px; padding-block: 24px; padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); line-height: 1.6 }
h1 { font-size: 1.4rem; margin: 0 0 4px; text-wrap: balance }
.lead { color: var(--muted); margin: 0 0 16px; max-width: 65ch }
nav { display: flex; flex-wrap: wrap; gap: 8px 16px; margin-bottom: 16px }
nav a { color: var(--accent); text-decoration: none; font-size: .95rem }
.tools { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; margin-bottom: 24px; padding: 10px 12px; border: 1px solid var(--border); border-radius: 8px }
.tools label { color: var(--muted); font-size: .9rem }
button, select { font: inherit; font-size: .9rem; padding: 4px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); color: #1f2328; cursor: pointer }
button:hover { border-color: var(--accent) }
section { margin-bottom: 36px }
.head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 12px }
h2 { font-size: 1.1rem; margin: 0 0 4px }
.note { color: var(--muted); font-size: .9rem; margin: 0 0 8px; max-width: 65ch }
.fig { background: var(--card); border: 1px solid var(--border); border-radius: 8px; overflow-x: auto; padding: 8px }
.fig svg { display: block; max-width: 100%; height: auto; margin-inline: auto }
code { font-family: ui-monospace, "JetBrains Mono", monospace; font-size: .9em }
.status { color: var(--muted); font-size: .85rem }
</style>
</head>
<body>
<h1>${escapeHtml(page.title)}</h1>
${page.leads.map((lead) => `<p class="lead">${lead}</p>\n`).join("")}<nav>
${page.sections
	.filter((s) => s.nav !== undefined)
	.map((s) => `<a href="#${s.id}">${escapeHtml(s.nav)}</a>`)
	.join("")}
</nav>
`;

const toolbar = `<div class="tools">
<label for="scale">PNG の倍率</label>
<select id="scale"><option value="1">1x</option><option value="2" selected>2x</option><option value="3">3x</option></select>
<button type="button" id="save-all">すべて PNG で保存</button>
<span class="status" id="status">各図の見出しの横のボタンで 1 枚ずつ保存できます。文字はこの PC のフォントで描かれます</span>
</div>
`;

const buttons = '<button type="button" class="save-png">PNG を保存</button><button type="button" class="save-svg">SVG を保存</button>\n';

const section = (s) => {
	const svg = readFileSync(join(dir, `${s.file}.svg`), "utf8");
	return [
		`<section id="${s.id}" data-file="${s.file}"><div class="head"><h2>${escapeHtml(s.heading)}</h2>\n`,
		tools ? buttons : "",
		`</div><p class="note">${s.note}</p><div class="fig">\n`,
		svg,
		"</div></section>\n",
	].join("");
};

const html = [head, tools ? toolbar : "", ...page.sections.map(section), tools ? `<script>\n${saveButtonsJs}</script>\n` : "", "</body></html>\n"].join("");

writeFileSync(join(dir, outName), html);
console.log(`wrote ${join(dir, outName)}`);
