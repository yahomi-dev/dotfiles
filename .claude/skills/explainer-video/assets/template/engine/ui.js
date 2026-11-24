// ui.js — 操作の場面。モック画面 (HTML) を窓に入れて舞台の中央に置き、カーソル・クリック・入力・ズームを events で動かす。
// 画面録画ではなく「その瞬間の画面を HTML で描く」ので、何度撮っても同じ絵になり、数字を直して撮り直せる。
(() => {
  const { W, CONTENT_H, h } = EV;

  const FRAMES = {
    browser: { w: 1180, h: 660 },
    app: { w: 1180, h: 660 },
    phone: { w: 360, h: 700 },
    none: { w: 1180, h: 660 },
  };

  const chrome = (frame, scr) => {
    if (frame === 'phone' || frame === 'none') return null;
    const dots = ['#ff5f57', '#febc2e', '#28c840'].map((c) => h('span', { class: 'win-dot', style: { background: c } }));
    const mid = frame === 'browser'
      ? h('div', { class: 'win-url', text: scr.url ?? 'localhost:3000' })
      : h('div', { class: 'win-title', text: scr.title ?? '' });
    return h('div', { class: 'win-bar' }, [...dots, mid, h('span', { style: { width: '52px' } })]);
  };

  EV.defineScene('ui', (spec, ctx) => {
    const scr = spec.screen || {};
    const frame = scr.frame ?? 'browser';
    const size = FRAMES[frame] ?? FRAMES.browser;
    const w = scr.w ?? size.w;
    const hh = scr.h ?? size.h;
    const x = scr.x ?? (W - w) / 2;
    const y = scr.y ?? (CONTENT_H - hh) / 2 + 8;
    const win = h('div', { class: `win win-${frame}`, style: { left: `${x}px`, top: `${y}px`, width: `${w}px`, height: `${hh}px` } }, [
      chrome(frame, scr),
      h('div', { class: 'win-body', html: scr.html ?? '' }),
    ]);
    const fx = h('div', { class: 'fx' });
    const camera = h('div', { class: 'camera' }, [win, fx]);
    const el = h('div', { class: 'scene scene-ui' }, [h('div', { class: 'clip' }, [camera])]);
    const rt = EV.events(spec, { root: win, camera, fx, cursor: spec.cursor !== false, measure: ctx.measure });
    if (spec.mount) spec.mount(win, ctx);
    return { el, prepare: rt.prepare, render: rt.render, captionAt: rt.captionAt, kickerAt: rt.kickerAt, win };
  });
})();
