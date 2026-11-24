// util.js — 全エンジン共通の小道具。window.EV にまとめる
// 乱数や実時間は使わない。t が同じなら必ず同じ絵になるように、すべて t から計算する
window.EV = (() => {
  const W = 1600;
  const H = 900;
  const CONTENT_H = 730; // 字幕の帯 (下 170px) を除いた高さ

  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const ramp = (t, a, b) => (b <= a ? (t >= b ? 1 : 0) : clamp((t - a) / (b - a)));
  const lerp = (a, b, k) => a + (b - a) * k;
  const easeOut = (x) => 1 - Math.pow(1 - clamp(x), 3);
  const easeInOut = (x) => {
    const k = clamp(x);
    return k < 0.5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2;
  };
  const easeBack = (x) => {
    const k = clamp(x);
    const c = 1.7;
    return 1 + (c + 1) * Math.pow(k - 1, 3) + c * Math.pow(k - 1, 2);
  };

  // DOM を作る: h('div', { class: 'x', text: '...', style: { left: '1px' }, 'data-id': 'go' }, [children])
  const h = (tag, attrs = {}, children = []) => {
    const e = document.createElement(tag);
    Object.entries(attrs).forEach(([k, v]) => {
      if (v === undefined || v === null || v === false) return;
      if (k === 'class') e.className = v;
      else if (k === 'text') e.textContent = v;
      else if (k === 'html') e.innerHTML = v;
      else if (k === 'style' && typeof v === 'object') {
        Object.entries(v).forEach(([p, val]) => {
          if (val === undefined || val === null) return;
          if (p.startsWith('--')) e.style.setProperty(p, val);
          else e.style[p] = val;
        });
      } else e.setAttribute(k, v);
    });
    [].concat(children).filter(Boolean).forEach((c) => e.append(c));
    return e;
  };

  const NS = 'http://www.w3.org/2000/svg';
  const svg = (tag, attrs = {}, parent) => {
    const e = document.createElementNS(NS, tag);
    Object.entries(attrs).forEach(([k, v]) => e.setAttribute(k, v));
    if (parent) parent.append(e);
    return e;
  };
  const svgText = (s, attrs, parent) => {
    const e = svg('text', attrs, parent);
    e.textContent = s;
    return e;
  };

  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const ids = (v) => (Array.isArray(v) ? v : [v]);

  // 場面の種類 (kind) ごとの組み立て関数。core.js が TIMELINE.scenes[].kind で引く
  const registry = {};
  const defineScene = (kind, factory) => {
    registry[kind] = factory;
  };

  return { W, H, CONTENT_H, clamp, ramp, lerp, easeOut, easeInOut, easeBack, h, svg, svgText, esc, ids, registry, defineScene };
})();
