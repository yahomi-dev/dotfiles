// render.mjs — index.html をヘッドレス Chromium で開き、VIDEO.render(t) を 1 コマずつ撮って書き出す (出力は out/)
//   node tools/render.mjs info                      -> 尺と場面の時刻表
//   node tools/render.mjs sheet [枚数=16]            -> out/sheet.png (全体を等間隔に撮ったコンタクトシート、時刻入り)
//   node tools/render.mjs scene <番号|id> [枚数=8]   -> out/scene-<番号>.png (その場面だけのコンタクトシート)
//   node tools/render.mjs stills 2.5,7.1            -> out/still-<秒>.png (原寸 1920x1080)
//   node tools/render.mjs video [名前=video]         -> out/<名前>.mp4 (H.264 30fps) + <名前>-poster.png。--gif を付けると <名前>.gif (15MB 以下) も作る
//   共通オプション: --page <html> (既定 index.html) / --out <dir> (既定 out)
//   環境変数: EV_CHROME (Chromium の実行ファイル) / EV_FFMPEG (ffmpeg の実行ファイル)
import { spawn, spawnSync } from 'node:child_process';
import { once } from 'node:events';
import fs from 'node:fs';
import { createRequire } from 'node:module';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { chromium } from 'playwright-core';

const require = createRequire(import.meta.url);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const takeOpt = (name, dflt) => {
  const i = argv.indexOf(name);
  if (i < 0) return dflt;
  return argv.splice(i, 2)[1];
};
const takeFlag = (name) => {
  const i = argv.indexOf(name);
  if (i < 0) return false;
  argv.splice(i, 1);
  return true;
};
const PAGE = takeOpt('--page', 'index.html');
const OUT = path.resolve(root, takeOpt('--out', 'out'));
const WANT_GIF = takeFlag('--gif');
const [mode = 'info', ...args] = argv;
fs.mkdirSync(OUT, { recursive: true });

// ---- Chromium: EV_CHROME -> Playwright のキャッシュ (新しい版から) -> インストール済み Chrome ----
const pwCache = () => process.env.PLAYWRIGHT_BROWSERS_PATH || (process.platform === 'win32'
  ? path.join(process.env.LOCALAPPDATA || '', 'ms-playwright')
  : process.platform === 'darwin'
    ? path.join(os.homedir(), 'Library', 'Caches', 'ms-playwright')
    : path.join(os.homedir(), '.cache', 'ms-playwright'));
const cachedDirs = (prefix) => {
  try {
    return fs.readdirSync(pwCache())
      .filter((d) => new RegExp(`^${prefix}-\\d+$`).test(d))
      .sort((a, b) => Number(b.split('-').at(-1)) - Number(a.split('-').at(-1)));
  } catch {
    return [];
  }
};
const findChrome = () => {
  if (process.env.EV_CHROME) return { executablePath: process.env.EV_CHROME };
  const rels = process.platform === 'win32'
    ? [['chrome-win64', 'chrome.exe'], ['chrome-win', 'chrome.exe']]
    : process.platform === 'darwin'
      ? [
        ['chrome-mac-arm64', 'Google Chrome for Testing.app', 'Contents', 'MacOS', 'Google Chrome for Testing'],
        ['chrome-mac', 'Google Chrome for Testing.app', 'Contents', 'MacOS', 'Google Chrome for Testing'],
        ['chrome-mac-arm64', 'Chromium.app', 'Contents', 'MacOS', 'Chromium'],
        ['chrome-mac', 'Chromium.app', 'Contents', 'MacOS', 'Chromium'],
      ]
      : [['chrome-linux64', 'chrome'], ['chrome-linux', 'chrome']];
  const hit = cachedDirs('chromium').flatMap((d) => rels.map((r) => path.join(pwCache(), d, ...r))).find((p) => fs.existsSync(p));
  return hit ? { executablePath: hit } : { channel: 'chrome' };
};

// ---- ffmpeg: EV_FFMPEG -> PATH の ffmpeg -> npm の ffmpeg-static ----
// Playwright 同梱の ffmpeg (ms-playwright/ffmpeg-*) は VP8/webm 専用で H.264 も tile も無いので使わない
const findFfmpeg = () => {
  if (process.env.EV_FFMPEG) return process.env.EV_FFMPEG;
  const sys = spawnSync('ffmpeg', ['-version'], { stdio: 'ignore' });
  if (!sys.error && sys.status === 0) return 'ffmpeg';
  try {
    const p = require('ffmpeg-static');
    if (p && fs.existsSync(p)) return p;
  } catch {
    // ffmpeg-static が無い
  }
  throw new Error('ffmpeg が見つかりません。`npm install` (ffmpeg-static が入る) か、ffmpeg を PATH に入れるか、EV_FFMPEG=<path> を指定してください');
};
// ffmpeg が要るのは video だけ。info / sheet / scene / stills は ffmpeg 無しで動く
const memo = {};
const ffmpegPath = () => {
  memo.ffmpeg ??= findFfmpeg();
  return memo.ffmpeg;
};
const ffmpeg = (fargs, stdin = 'ignore') => spawn(ffmpegPath(), ['-y', '-loglevel', 'error', ...fargs], { stdio: [stdin, 'inherit', 'inherit'] });
const finish = async (ff) => {
  const [code] = await once(ff, 'close');
  if (code !== 0) throw new Error(`ffmpeg exited with ${code}`);
};
const write = async (ff, buf) => {
  if (!ff.stdin.write(buf)) await once(ff.stdin, 'drain');
};
// コンタクトシートはブラウザ側で並べて撮る (ffmpeg 不要)
const tileSheet = async (browser, file, frames, cols = 4) => {
  const tile = await browser.newPage({ viewport: { width: cols * 484 + 4, height: 64 }, deviceScaleFactor: 1 });
  const imgs = frames.map((b) => `<img src="data:image/jpeg;base64,${b.toString('base64')}">`).join('');
  await tile.setContent(`<!doctype html><body style="margin:0;background:#fff"><style>img{width:480px;height:auto;display:block}</style><div style="display:grid;grid-template-columns:repeat(${cols},480px);gap:4px;padding:4px;width:max-content">${imgs}</div></body>`);
  await tile.screenshot({ path: file, fullPage: true });
  await tile.close();
};

// ---- ページを開く。論理 1600x900 を 1.2 倍で撮る -> 1920x1080 ----
const browser = await chromium.launch({ ...findChrome(), headless: true });
const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1.2 });
const pageErrors = [];
page.on('console', (m) => console.log('[page]', m.text()));
page.on('pageerror', (e) => {
  pageErrors.push(e.message);
  console.error('[pageerror]', e.message);
});
await page.goto(`${pathToFileURL(path.join(root, PAGE)).href}?render`);
try {
  await page.waitForFunction(() => window.VIDEO && window.VIDEO.ready === true, null, { timeout: 60000 });
} catch (e) {
  await browser.close();
  throw new Error(`ページが ready になりません (${PAGE})。${pageErrors.length ? `ページのエラー: ${pageErrors.join(' / ')}` : e.message}`);
}
const { duration: DUR, fps: FPS, posterTime, phases } = await page.evaluate(() => ({
  duration: window.VIDEO.duration, fps: window.VIDEO.fps, posterTime: window.VIDEO.posterTime, phases: window.VIDEO.phases,
}));
const shot = async (t, type = 'png', stamp = false) => {
  await page.evaluate(([tt, s]) => window.VIDEO.render(tt, { stamp: s }), [t, stamp]);
  return page.screenshot(type === 'png' ? { type } : { type, quality: 95 });
};
const seq = (n) => Array.from({ length: n }, (_, i) => i);
const takeAll = (times, stamp) => times.reduce((p, t) => p.then(async (acc) => [...acc, await shot(t, 'jpeg', stamp)]), Promise.resolve([]));

if (mode === 'info') {
  console.log(`duration ${DUR.toFixed(2)}s  fps ${FPS}  frames ${Math.round(DUR * FPS)}  poster ${posterTime.toFixed(2)}s`);
  phases.forEach((p, i) => console.log(`${String(i + 1).padStart(2)} ${p.kind.padEnd(6)} ${p.t0.toFixed(2).padStart(6)} - ${p.t1.toFixed(2).padStart(6)}  ${p.id ? `[${p.id}] ` : ''}${p.caption}`));
}

if (mode === 'sheet') {
  const n = Math.ceil(Number(args[0] || 16) / 4) * 4;
  const file = path.join(OUT, 'sheet.png');
  await tileSheet(browser, file, await takeAll(seq(n).map((i) => ((i + 0.5) / n) * DUR), true));
  console.log(`${file} (${n} frames)`);
}

if (mode === 'scene') {
  const key = args[0];
  const idx = /^\d+$/.test(key) ? Number(key) - 1 : phases.findIndex((p) => p.id === key);
  const p = phases[idx];
  if (!p) throw new Error(`scene not found: ${key} (info で番号か id を確認してください)`);
  const n = Math.ceil(Number(args[1] || 8) / 4) * 4;
  const file = path.join(OUT, `scene-${idx + 1}.png`);
  await tileSheet(browser, file, await takeAll(seq(n).map((i) => p.t0 + ((i + 0.5) / n) * (p.t1 - p.t0)), true));
  console.log(`${file} (${p.kind} ${p.t0}-${p.t1}s, ${n} frames)`);
}

if (mode === 'stills') {
  const times = (args[0] || String(posterTime)).split(',').map(Number);
  await times.reduce((pr, t) => pr.then(async () => fs.writeFileSync(path.join(OUT, `still-${t}.png`), await shot(t))), Promise.resolve());
  console.log(`stills written: ${times.map((t) => `still-${t}.png`).join(', ')}`);
}

if (mode === 'video') {
  const name = args[0] || 'video';
  const n = Math.round(DUR * FPS);
  const mp4 = path.join(OUT, `${name}.mp4`);
  const started = Date.now();
  const ff = ffmpeg(['-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-profile:v', 'high', '-movflags', '+faststart', mp4], 'pipe');
  await seq(n).reduce((p, i) => p.then(async () => {
    await write(ff, await shot(i / FPS, 'jpeg'));
    if (i % 90 === 0) console.log(`frame ${i}/${n}  ${((Date.now() - started) / 1000).toFixed(1)}s`);
  }), Promise.resolve());
  ff.stdin.end();
  await finish(ff);
  fs.writeFileSync(path.join(OUT, `${name}-poster.png`), await shot(posterTime));
  console.log(`${mp4}  (${n} frames, ${((Date.now() - started) / 1000).toFixed(1)}s)`);

  if (WANT_GIF) {
    // 動く部分に色を割く (stats_mode=diff)。X の上限 15MB に収まるまで幅と fps を落とす
    const gif = path.join(OUT, `${name}.gif`);
    await [[960, 15], [800, 12], [640, 10]].reduce((p, [w, f]) => p.then(async (done) => {
      if (done) return true;
      const vf = `fps=${f},scale=${w}:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle`;
      await finish(ffmpeg(['-i', mp4, '-vf', vf, '-loop', '0', gif]));
      const mb = fs.statSync(gif).size / 1e6;
      console.log(`${gif}  ${w}px ${f}fps  ${mb.toFixed(1)}MB`);
      return mb <= 15;
    }), Promise.resolve(false));
  }
}

await browser.close();
