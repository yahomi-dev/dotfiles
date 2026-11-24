// arch.js — 構成図の場面。全体の構成図のうち「いま関係する部分」を操作の合間に差し込む。
// ノードが順に現れ、線が引かれ、focus のノードだけ明るく、flow の線を光の粒が流れ続ける。
// 元: musoukun/skills animated-arch-diagram の engine.js を 1 場面用に切り詰めたもの
(() => {
  const { W, CONTENT_H, h, svg, svgText, ramp, lerp, easeOut, easeInOut, easeBack } = EV;
  const POP = 0.45;

  EV.defineScene('arch', (spec, ctx) => {
    const T = ctx.theme;
    const root = svg('svg', { viewBox: `0 0 ${W} ${CONTENT_H}` });
    const el = h('div', { class: 'scene arch-scene' }, [root]);
    const GAP = spec.gap ?? 0.15;
    const nodes = (spec.nodes || []).map((n, i) => ({ ...n, t0: 0.3 + i * GAP }));
    const byId = Object.fromEntries(nodes.map((n) => [n.id, n]));
    const intro = (nodes.at(-1)?.t0 ?? 0) + POP + 0.4;
    const dur = spec.dur ?? 5;

    const [GC, GR] = spec.grid || [3, 2];
    const PX = 100;
    const TOP = spec.title ? 150 : 50;
    const BOTTOM = 40;
    const cw = (W - PX * 2) / GC;
    const ch = (CONTENT_H - TOP - BOTTOM) / GR;
    nodes.forEach((n) => {
      n.x = PX + (n.col + 0.5) * cw;
      n.y = TOP + (n.row + 0.5) * ch;
      n.w = n.w ?? Math.min(300, cw - 40);
      n.h = n.h ?? 92;
    });

    const edgePath = (a, b) => {
      if (Math.abs(a.y - b.y) > 1) {
        const s = a.y < b.y ? 1 : -1;
        const x1 = a.x;
        const y1 = a.y + (s * a.h) / 2;
        const x2 = b.x;
        const y2 = b.y - (s * b.h) / 2;
        const m = (y2 - y1) / 2;
        return `M${x1},${y1} C${x1},${y1 + m} ${x2},${y2 - m} ${x2},${y2}`;
      }
      const s = a.x < b.x ? 1 : -1;
      return `M${a.x + (s * a.w) / 2},${a.y} L${b.x - (s * b.w) / 2},${b.y}`;
    };

    const defs = svg('defs', {}, root);
    defs.innerHTML = `
      <filter id="aglow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="18"/></filter>
      <filter id="aglowS" x="-300%" y="-300%" width="700%" height="700%"><feGaussianBlur stdDeviation="5"/></filter>`;
    const gTitle = svg('g', {}, root);
    const gEdges = svg('g', {}, root);
    const gFx = svg('g', {}, root);
    const gNodes = svg('g', {}, root);
    const gBadges = svg('g', {}, root);
    if (spec.title) {
      svgText(spec.title, { x: PX, y: 86, fill: T.fg, 'font-family': T.font, 'font-size': 40, 'font-weight': 900 }, gTitle);
      if (spec.subtitle) svgText(spec.subtitle, { x: PX, y: 124, fill: T.dim, 'font-family': T.font, 'font-size': 22 }, gTitle);
    }

    const edges = (spec.edges || []).map((e) => {
      const a = byId[e.from];
      const b = byId[e.to];
      if (!a || !b) throw new Error(`arch: unknown node in edge ${e.from} -> ${e.to}`);
      const d = edgePath(a, b);
      const base = svg('path', { d, fill: 'none', stroke: T.edge, 'stroke-width': 2.5, 'stroke-linecap': 'round' }, gEdges);
      const hot = svg('path', { d, fill: 'none', stroke: a.color, 'stroke-width': 3, 'stroke-linecap': 'round', opacity: 0 }, gEdges);
      const len = base.getTotalLength();
      if (e.dashed) {
        base.setAttribute('stroke-dasharray', '7 9');
        hot.setAttribute('stroke-dasharray', '7 9');
      } else base.setAttribute('stroke-dasharray', `${len} ${len}`);
      const mid = base.getPointAtLength(len / 2);
      const label = e.label ? svgText(e.label, { x: mid.x + 10, y: mid.y - 8, fill: T.dim, 'font-family': T.mono, 'font-size': 14 }, gEdges) : null;
      return { ...e, a, b, base, hot, len, label, t0: Math.max(a.t0, b.t0) + POP * 0.6 };
    });
    const findEdge = (f, t) => {
      const fwd = edges.find((e) => e.from === f && e.to === t);
      if (fwd) return { e: fwd, rev: false };
      const back = edges.find((e) => e.from === t && e.to === f);
      if (back) return { e: back, rev: true };
      console.warn(`edge not found: ${f} -> ${t} (edges に足してください)`);
      return null;
    };
    const hops = (spec.flow || []).map(([f, t]) => findEdge(f, t)).filter(Boolean);
    const hop = spec.hop ?? 0.8;

    nodes.forEach((n) => {
      const box = { x: -n.w / 2, y: -n.h / 2, width: n.w, height: n.h, rx: 16 };
      n.g = svg('g', {}, gNodes);
      n.glow = svg('rect', { ...box, fill: n.color, filter: 'url(#aglow)', opacity: 0 }, n.g);
      n.ringG = svg('g', { opacity: 0 }, n.g);
      svg('rect', { ...box, fill: 'none', stroke: n.color, 'stroke-width': 2 }, n.ringG);
      svg('rect', { ...box, fill: T.card, stroke: n.color, 'stroke-width': 2 }, n.g);
      svg('rect', { x: -n.w / 2 + 12, y: -n.h / 2 + 18, width: 5, height: n.h - 36, rx: 2.5, fill: n.color }, n.g);
      const lx = -n.w / 2 + 32;
      svgText(n.label, { x: lx, y: n.sub ? -2 : 9, fill: T.fg, 'font-family': T.font, 'font-size': 27, 'font-weight': 700 }, n.g);
      if (n.sub) svgText(n.sub, { x: lx, y: 26, fill: T.dim, 'font-family': T.mono, 'font-size': 16 }, n.g);
      if (n.tag) {
        const tg = svg('g', {}, n.g);
        const tt = svgText(n.tag, { x: 0, y: 5, fill: n.color, 'font-family': T.mono, 'font-size': 14, 'font-weight': 700, 'text-anchor': 'middle' }, tg);
        n.tagParts = { tg, tt };
      }
    });

    const layoutTags = () => nodes.forEach((n) => {
      if (!n.tagParts) return;
      const { tg, tt } = n.tagParts;
      const w = tt.getComputedTextLength() + 22;
      tg.querySelector('rect')?.remove();
      tg.insertBefore(svg('rect', { x: -w / 2, y: -12, width: w, height: 24, rx: 12, fill: T.bg, stroke: n.color, 'stroke-width': 1.5 }), tt);
      tg.setAttribute('transform', `translate(${n.w / 2 - w / 2 - 16} ${-n.h / 2})`);
    });

    const packet = (e, rev, p, color) => {
      const at = (q) => e.base.getPointAtLength((rev ? 1 - q : q) * e.len);
      [5, 4, 3, 2, 1].forEach((k) => {
        const pt = at(Math.max(0, p - k * 0.035));
        svg('circle', { cx: pt.x, cy: pt.y, r: 6 - k * 0.8, fill: color, opacity: 0.55 - k * 0.08 }, gFx);
      });
      const hd = at(p);
      svg('circle', { cx: hd.x, cy: hd.y, r: 15, fill: color, filter: 'url(#aglowS)', opacity: 0.9 }, gFx);
      svg('circle', { cx: hd.x, cy: hd.y, r: 7, fill: color }, gFx);
      svg('circle', { cx: hd.x, cy: hd.y, r: 3.2, fill: '#fff' }, gFx);
    };
    const badge = (n, text, k, fade) => {
      const g = svg('g', { opacity: fade }, gBadges);
      const t = svgText(text, { x: 0, y: 7, fill: T.bg, 'font-family': T.font, 'font-size': 20, 'font-weight': 900, 'text-anchor': 'middle' }, g);
      const w = t.getComputedTextLength() + 32;
      g.insertBefore(svg('rect', { x: -w / 2, y: -18, width: w, height: 36, rx: 18, fill: n.color }), t);
      g.setAttribute('transform', `translate(${n.x} ${n.y - n.h / 2 - 40}) scale(${lerp(0.5, 1, easeBack(k))})`);
    };

    const render = (lt) => {
      gFx.innerHTML = '';
      gBadges.innerHTML = '';
      const pulse = {};
      const hot = new Map();
      const focusK = spec.focus ? easeInOut(ramp(lt, intro, intro + 0.35)) : 0;

      if (hops.length) {
        const span = dur - intro - 0.2;
        const cyc = hops.length * hop + 0.35;
        const l = lt - intro;
        Array.from({ length: Math.max(0, Math.ceil(span / cyc)) }, (_, c) => c).forEach((c) => hops.forEach((hp, i) => {
          const st = 0.2 + c * cyc + i * hop;
          const en = st + hop;
          if (en > span) return;
          const target = hp.rev ? hp.e.a : hp.e.b;
          const col = (hp.rev ? hp.e.b : hp.e.a).color;
          if (l >= st && l <= en) {
            packet(hp.e, hp.rev, easeInOut(ramp(l, st, en)), col);
            hot.set(hp.e, 1);
            hp.e.hot.setAttribute('stroke', col);
          } else if (l > en && l < en + 0.6) {
            pulse[target.id] = Math.max(pulse[target.id] || 0, 1 - (l - en) / 0.6);
            hot.set(hp.e, Math.max(hot.get(hp.e) || 0, 1 - (l - en) / 0.4));
          }
        }));
      }

      edges.forEach((e) => {
        const k = easeOut(ramp(lt, e.t0, e.t0 + 0.5));
        if (e.dashed) {
          e.base.setAttribute('opacity', k);
          e.base.setAttribute('stroke-dashoffset', -lt * 30);
          e.hot.setAttribute('stroke-dashoffset', -lt * 30);
        } else e.base.setAttribute('stroke-dashoffset', e.len * (1 - k));
        e.hot.setAttribute('opacity', hot.get(e) || 0);
        if (e.label) e.label.setAttribute('opacity', k);
      });

      nodes.forEach((n) => {
        const k = ramp(lt, n.t0, n.t0 + POP);
        const focused = !spec.focus || spec.focus.includes(n.id);
        const bright = lerp(1, focused ? 1 : 0.28, focusK);
        const glow = focused && spec.focus ? focusK : 0;
        const pu = pulse[n.id] || 0;
        n.g.setAttribute('transform', `translate(${n.x} ${n.y}) scale(${lerp(0.6, 1, easeBack(k)) * (1 + pu * 0.04)})`);
        n.g.setAttribute('opacity', easeOut(k) * bright);
        n.glow.setAttribute('opacity', Math.max(glow * 0.45, pu * 0.8));
        n.ringG.setAttribute('opacity', pu * 0.9);
        n.ringG.setAttribute('transform', `scale(${1 + (1 - pu) * 0.18})`);
      });

      (spec.badges || []).forEach((b, i, all) => {
        const next = all.slice(i + 1).find((x) => x.node === b.node);
        const at = b.at ?? intro + 0.2;
        const end = next ? next.at : dur - 0.15;
        if (lt >= at && lt < end && byId[b.node]) badge(byId[b.node], b.text, ramp(lt, at, at + 0.35), 1 - ramp(lt, end - 0.15, end));
      });
      gTitle.setAttribute('opacity', easeOut(ramp(lt, 0, 0.6)));
    };

    const rt = EV.events(spec, { root: el, camera: null, fx: h('div'), cursor: false, measure: ctx.measure });
    return {
      el,
      prepare: () => {
        layoutTags();
        rt.prepare();
      },
      render: (lt) => {
        render(lt);
        rt.render(lt);
      },
      captionAt: rt.captionAt,
      kickerAt: rt.kickerAt,
    };
  });
})();
