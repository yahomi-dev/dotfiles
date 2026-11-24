// timeline.js — 動画の中身 (window.TIMELINE)。書き換えるのは基本このファイルと data.js だけ。書式は references/timeline.md
// 例: 架空アプリ「議事録まとめ」が、貼り付けた議事録から要点 3 つを返すまで。操作 -> 仕組み -> 仕組み -> 仕組み -> 操作 の順
const R = window.RECORD;
const AI = '#f59e0b'; // AI
const PG = '#22d3ee'; // プログラム
const CU = '#e2e8f0'; // お客様

// 操作の場面のモック画面。state (results) で「結果が出ている / いない」を切り替えて 2 つの操作場面で使い回す
const screen = ({ results = false } = {}) => `
<div class="app">
  <div class="app-header"><span class="logo"></span>${R.app}<span class="spacer"></span><span class="avatar"></span></div>
  <div class="app-body">
    <div class="pane">
      <div class="pane-title">議事録</div>
      <div class="field multiline${results ? ' typed' : ''}" data-id="input">${results ? R.input : '議事録を貼り付けてください'}</div>
      <div class="row right"><button class="btn primary" data-id="go">まとめる</button></div>
    </div>
    <div class="pane">
      <div class="pane-title">要点</div>
      <div class="card" data-id="result"${results ? '' : ' data-hidden'}>
        <div class="card-title">${R.picked.length} 件 <span class="muted">(${R.elapsedMs} ms)</span></div>
        <div class="list">
          ${R.picked.map((p, i) => `<div class="item" data-id="r${i}" data-hidden><span class="num">${i + 1}</span><span>${R.sentences[p]}</span></div>`).join('')}
        </div>
        <div class="row right" style="margin-top: 14px"><button class="btn small" data-id="copy">コピー</button></div>
      </div>
    </div>
  </div>
  <div class="toast" data-id="toast" data-hidden>コピーしました</div>
</div>`;

window.TIMELINE = {
  fps: 30,
  scenes: [
    { kind: 'title', dur: 3, title: '「議事録まとめ」は何をしているのか', subtitle: '1 回の操作を、画面と仕組みで交互に追う' },

    // ---- 操作 1: 貼り付けて「まとめる」を押す ----
    {
      kind: 'ui', id: 'paste', dur: 10, caption: '議事録を貼り付けて「まとめる」を押す',
      screen: { url: 'minutes.example.app', html: screen() },
      events: [
        { at: 0.5, move: 'input' },
        { at: 1.2, type: 'input', text: R.input, cps: 40, zoom: 1.35 },
        { at: 4.6, zoom: 'reset' },
        { at: 5.8, click: 'go', zoom: 1.6, caption: '押した瞬間、裏で処理が始まる' },
        { at: 8.4, zoom: 'reset' },
      ],
    },

    // ---- 仕組み 1: 文に区切る (プログラム) ----
    {
      kind: 'mech', id: 'split', dur: 9, caption: `送られた文章を、プログラムが ${R.sentences.length} 文に区切る`,
      items: [
        { id: 'src', type: 'text', text: R.input, size: 32 },
        { id: 'sent', type: 'chips', items: R.sentences, color: PG },
        { id: 'n', type: 'number', unit: '文' },
      ],
      events: [
        { at: 0.3, show: 'src' },
        { at: 2.4, split: 'src', into: 'sent', stagger: 0.35 },
        { at: 4.8, show: 'n' },
        { at: 4.8, count: 'n', to: R.sentences.length, dur: 0.8 },
        { at: 5.6, caption: '区切るのはプログラム。AI はまだ出てこない' },
      ],
    },

    // ---- 仕組み 2: 構成図の該当部分だけ (サーバー <-> AI) ----
    {
      kind: 'arch', id: 'arch', dur: 6, caption: '区切った文を 1 つずつ AI に渡して、点数をもらう',
      grid: [3, 1],
      nodes: [
        { id: 'web', label: 'ブラウザ', sub: 'お客様の画面', color: CU, col: 0, row: 0 },
        { id: 'api', label: 'サーバー', sub: 'プログラム', color: PG, col: 1, row: 0 },
        { id: 'ai', label: 'AI', sub: '採点だけ', color: AI, col: 2, row: 0 },
      ],
      edges: [{ from: 'web', to: 'api' }, { from: 'api', to: 'ai' }],
      focus: ['api', 'ai'],
      flow: [['api', 'ai'], ['ai', 'api']],
      hop: 0.6,
      badges: [{ node: 'ai', text: '重要度 0〜1 を返す', at: 2.4 }],
    },

    // ---- 仕組み 3: 点数で並べ替えて上位を残す (プログラム) ----
    {
      kind: 'mech', id: 'rank', dur: 11, caption: 'AI の点数で並べ替え、上位 3 文を残す',
      items: [
        { id: 'bars', type: 'bars', color: AI, max: 1, items: R.sentences.map((s, i) => ({ label: s, value: R.scores[i], text: R.scores[i].toFixed(2) })) },
        { id: 'note', type: 'note', html: `上位 <b>${R.picked.length} 文</b> を要点として返す。点数を付けるのは AI、並べ替えて選ぶのはプログラム` },
      ],
      events: [
        { at: 0.3, show: 'bars', stagger: 0.3 },
        { at: 3.4, sort: 'bars', by: 'value', desc: true, dur: 1.0 },
        { at: 4.8, mark: 'bars', index: R.picked },
        { at: 5.4, show: 'note' },
        { at: 6.2, caption: '点数は AI、選ぶのはプログラム' },
      ],
    },

    // ---- 操作 2: 結果が画面に返ってくる ----
    {
      kind: 'ui', id: 'result', dur: 9, caption: `要点が ${R.picked.length} つ、画面に返ってくる`,
      screen: { url: 'minutes.example.app', html: screen({ results: true }) },
      cursor: { x: 1120, y: 600 },
      events: [
        { at: 0.5, show: 'r0' },
        { at: 0.9, show: 'r1' },
        { at: 1.3, show: 'r2' },
        { at: 1.0, zoom: { to: 'result', scale: 1.4 } },
        { at: 3.4, zoom: 'reset' },
        { at: 4.4, click: 'copy', zoom: 1.3, caption: 'コピーして、そのまま共有できる' },
        { at: 4.5, show: 'toast' },
        { at: 6.6, hide: 'toast' },
        { at: 7.0, zoom: 'reset' },
      ],
    },

    { kind: 'outro', dur: 4, title: 'AI は文に点を付けるだけ。区切りと並べ替えはプログラム。', subtitle: `${R.sentences.length} 文 -> ${R.picked.length} 件、${R.elapsedMs} ms` },
  ],
};
