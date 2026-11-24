// mech.js — 仕組みの場面。入力されたデータを画面いっぱいに広げ、処理の動き (区切る・採点する・並べ替える・運ぶ) を見せる。
// items に部品を並べ、events で動かす。部品の種類: text / note / html / chips / bars / number / boxes
// 糖衣 (この場面だけの語彙): split (text -> chips) / sort (bars) / count (number) / flow (boxes) / index (mark 等の対象を子要素に)
(() => {
  const { h, svg, svgText, ramp, lerp, easeOut, easeInOut, ids, esc } = EV;
  const STAGGER = 0.2;
  const hidden = (it) => (it.visible ? undefined : '');
  const px = (v) => (v == null ? undefined : `${v}px`);

  const builders = {
    text: (it) => ({
      el: h('div', { class: 'm-text', 'data-id': it.id, 'data-hidden': hidden(it), html: it.html ?? esc(it.text ?? ''), style: { fontSize: px(it.size), maxWidth: px(it.w), color: it.color } }),
    }),
    note: (it) => ({
      el: h('div', { class: 'm-note', 'data-id': it.id, 'data-hidden': hidden(it), html: it.html ?? esc(it.text ?? ''), style: { fontSize: px(it.size), maxWidth: px(it.w), color: it.color } }),
    }),
    html: (it) => ({
      el: h('div', { class: 'm-html', 'data-id': it.id, 'data-hidden': hidden(it), html: it.html ?? '', style: { width: px(it.w) } }),
    }),

    // 札の並び。子は `${id}.${i}` で指せる (mark: 'chips', index: 1 でも可)
    chips: (it) => {
      const chips = (it.items || []).map((c, i) => {
        const o = typeof c === 'string' ? { text: c } : c;
        return h('span', { class: 'chip', 'data-id': `${it.id}.${i}`, 'data-hidden': '', text: o.text, style: { '--c': o.color ?? it.color ?? 'var(--accent)', fontSize: px(it.size) } });
      });
      const el = h('div', { class: 'm-chips', 'data-id': it.id, 'data-hidden': hidden(it), style: { maxWidth: px(it.w), gap: px(it.gap) } }, chips);
      return { el, children: chips.length };
    },

    // 横棒グラフ。show で棒が伸び、sort で並び替わる (行の top を t から補間する)
    bars: (it) => {
      const items = it.items || [];
      const max = it.max ?? Math.max(...items.map((b) => b.value));
      const rowH = it.rowH ?? 48;
      const fills = [];
      const rows = items.map((b, i) => {
        const fill = h('div', { class: 'bar-fill', style: { width: '0%' } });
        fills.push(fill);
        return h('div', { class: 'bar-row', 'data-id': `${it.id}.${i}`, 'data-hidden': '', style: { top: `${i * rowH}px`, height: `${rowH}px`, '--c': b.color ?? it.color ?? 'var(--accent)' } }, [
          h('span', { class: 'bar-label', text: b.label, style: { width: px(it.labelW) } }),
          h('div', { class: 'bar-track' }, [fill]),
          h('span', { class: 'bar-val', text: b.text ?? String(b.value) }),
        ]);
      });
      const el = h('div', { class: 'm-bars', 'data-id': it.id, 'data-hidden': hidden(it), style: { height: `${items.length * rowH}px`, width: px(it.w) } }, rows);
      const state = { showAt: items.map(() => (it.visible ? 0 : Infinity)), sorts: [] };
      const sortBy = (prev, s) => {
        if (s.order) return s.order;
        const by = s.by ?? 'value';
        const dir = s.desc === false ? 1 : -1;
        return [...prev].sort((a, b) => (by === 'label' ? String(items[a].label).localeCompare(String(items[b].label)) * -dir : (items[a][by] - items[b][by]) * dir));
      };
      const render = (lt) => {
        const steps = state.sorts.reduce((acc, s) => {
          const prev = acc.at(-1).order;
          return [...acc, { at: s.at, dur: s.dur ?? 0.8, prev, order: sortBy(prev, s) }];
        }, [{ at: -Infinity, dur: 0, prev: items.map((_, i) => i), order: items.map((_, i) => i) }]);
        const cur = steps.reduce((c, s) => (lt >= s.at ? s : c), steps[0]);
        const k = easeInOut(ramp(lt, cur.at, cur.at + cur.dur));
        rows.forEach((row, i) => {
          const pos = lerp(cur.prev.indexOf(i), cur.order.indexOf(i), k);
          row.style.top = `${(pos * rowH).toFixed(2)}px`;
          const grow = easeOut(ramp(lt, state.showAt[i], state.showAt[i] + 0.7));
          fills[i].style.width = `${((items[i].value / max) * 100 * grow).toFixed(2)}%`;
        });
      };
      return { el, children: items.length, state, render };
    },

    // 大きな数字。count で from -> to に増える
    number: (it) => {
      const val = h('span', { class: 'val', text: String(it.from ?? 0) });
      const el = h('div', { class: 'm-number', 'data-id': it.id, 'data-hidden': hidden(it) }, [val, it.unit ? h('span', { class: 'unit', text: it.unit }) : null]);
      const state = { counts: [] };
      const render = (lt) => {
        const v = state.counts.reduce((cur, c) => (lt < c.at ? cur : lerp(c.from ?? cur, c.to, easeOut(ramp(lt, c.at, c.at + (c.dur ?? 1))))), it.from ?? 0);
        val.textContent = it.format ? it.format(v) : String(Math.round(v));
      };
      return { el, state, render };
    },

    // 箱の並び。flow で光る札が箱から箱へ運ばれる。子は `${id}.${boxId}`
    boxes: (it) => {
      const items = it.items || [];
      const boxes = items.map((b) => h('div', { class: 'box', 'data-id': `${it.id}.${b.id}`, style: { '--c': b.color ?? it.color ?? 'var(--accent)', minWidth: px(b.w ?? it.boxW) } }, [
        h('div', { class: 'box-label', text: b.label }),
        b.sub ? h('div', { class: 'box-sub', text: b.sub }) : null,
      ]));
      const fx = svg('svg', {});
      const el = h('div', { class: 'm-boxes', 'data-id': it.id, 'data-hidden': hidden(it), style: { gap: px(it.gap) } }, [...boxes, fx]);
      const state = { flows: [], rects: null };
      const prepare = (measure) => {
        state.rects = Object.fromEntries(items.map((b, i) => [b.id, measure(boxes[i], el)]));
      };
      const ends = (a, c) => (c.x > a.x
        ? { sx: a.x + a.w, sy: a.y + a.h / 2, ex: c.x, ey: c.y + c.h / 2 }
        : { sx: a.x, sy: a.y + a.h / 2, ex: c.x + c.w, ey: c.y + c.h / 2 });
      const render = (lt) => {
        fx.innerHTML = '';
        if (!state.rects) return;
        if (it.arrows !== false) items.slice(1).forEach((b, i) => {
          const { sx, sy, ex, ey } = ends(state.rects[items[i].id], state.rects[b.id]);
          svg('line', { x1: sx + 4, y1: sy, x2: ex - 10, y2: ey, stroke: 'var(--edge)', 'stroke-width': 3, 'stroke-linecap': 'round' }, fx);
          svg('path', { d: `M${ex - 14},${ey - 8} L${ex - 2},${ey} L${ex - 14},${ey + 8}`, fill: 'none', stroke: 'var(--edge)', 'stroke-width': 3, 'stroke-linejoin': 'round' }, fx);
        });
        state.flows.forEach((f) => {
          const a = state.rects[f.from];
          const c = state.rects[f.to];
          const k = lt - f.at;
          if (!a || !c || k < 0 || k > f.dur + 0.5) return;
          const { sx, sy, ex, ey } = ends(a, c);
          const q = easeInOut(ramp(lt, f.at, f.at + f.dur));
          const color = f.color ?? 'var(--accent)';
          if (q < 1) {
            const x = lerp(sx, ex, q);
            const y = lerp(sy, ey, q) - (f.arc ?? 0) * Math.sin(Math.PI * q);
            [4, 3, 2, 1].forEach((j) => {
              const qq = Math.max(0, q - j * 0.04);
              svg('circle', { cx: lerp(sx, ex, qq), cy: lerp(sy, ey, qq) - (f.arc ?? 0) * Math.sin(Math.PI * qq), r: 7 - j, fill: color, opacity: 0.5 - j * 0.1 }, fx);
            });
            svg('circle', { cx: x, cy: y, r: 18, fill: color, opacity: 0.35 }, fx);
            svg('circle', { cx: x, cy: y, r: 8, fill: color }, fx);
            if (f.text) {
              const g = svg('g', { transform: `translate(${x} ${y - 30})` }, fx);
              const t = svgText(f.text, { x: 0, y: 6, fill: '#0b0d12', 'font-size': 18, 'font-weight': 700, 'text-anchor': 'middle', 'font-family': 'var(--font)' }, g);
              const tw = t.getComputedTextLength() + 26;
              g.insertBefore(svg('rect', { x: -tw / 2, y: -15, width: tw, height: 30, rx: 15, fill: color }), t);
            }
          } else {
            const p = 1 - (k - f.dur) / 0.5;
            svg('rect', { x: c.x - 6, y: c.y - 6, width: c.w + 12, height: c.h + 12, rx: 20, fill: 'none', stroke: color, 'stroke-width': 3, opacity: p, transform: `translate(${c.x + c.w / 2} ${c.y + c.h / 2}) scale(${1 + (1 - p) * 0.12}) translate(${-(c.x + c.w / 2)} ${-(c.y + c.h / 2)})` }, fx);
          }
        });
      };
      return { el, state, prepare, render };
    },
  };

  EV.defineScene('mech', (spec, ctx) => {
    const wrap = h('div', { class: `mech${spec.layout === 'free' ? ' free' : ''}`, style: { gap: px(spec.gap), padding: spec.padding } });
    const items = (spec.items || []).map((it) => {
      const build = builders[it.type];
      if (!build) {
        console.warn(`unknown mech item type: ${it.type}`);
        return null;
      }
      const r = { ...build(it), it };
      if (it.x != null) Object.assign(r.el.style, { left: `${it.x}px`, top: `${it.y ?? 0}px` });
      wrap.append(r.el);
      return r;
    }).filter(Boolean);
    const byId = Object.fromEntries(items.map((r) => [r.it.id, r]));

    // 糖衣を primitive (show / cls / mark ...) に展開する。並び替え・カウント・運搬は部品の state に積む
    const staggered = (id, at, stagger) => {
      const r = byId[id];
      if (!r || !r.children) return [{ at, show: id }];
      const kids = Array.from({ length: r.children }, (_, i) => ({ at: at + 0.1 + i * stagger, show: `${id}.${i}` }));
      if (r.state?.showAt) kids.forEach((k, i) => { r.state.showAt[i] = k.at; });
      return [{ at, show: id }, ...kids];
    };
    const withIndex = (e) => {
      if (e.index == null) return e;
      const sub = (v) => ids(v).flatMap((id) => ids(e.index).map((i) => `${id}.${i}`));
      return { ...e, ...Object.fromEntries(['mark', 'unmark', 'cls', 'show', 'hide'].filter((k) => e[k] != null).map((k) => [k, sub(e[k])])) };
    };
    const events = (spec.events || []).flatMap((raw) => {
      const e = withIndex(raw);
      const out = [];
      if (e.split != null) {
        out.push({ at: e.at, cls: e.split, add: 'split' });
        out.push(...staggered(e.into, e.at + 0.25, e.stagger ?? STAGGER));
      }
      if (e.show != null) ids(e.show).forEach((id) => out.push(...(byId[id]?.children ? staggered(id, e.at, e.stagger ?? STAGGER) : [{ at: e.at, show: id, fade: e.fade }])));
      if (e.sort != null) byId[e.sort]?.state?.sorts.push({ at: e.at, by: e.by, desc: e.desc, order: e.order, dur: e.dur });
      if (e.count != null) byId[e.count]?.state?.counts.push({ at: e.at, from: e.from, to: e.to, dur: e.dur });
      if (e.flow != null) byId[e.flow]?.state?.flows.push({ at: e.at, from: e.from, to: e.to, dur: e.dur ?? 0.8, color: e.color, text: e.text, arc: e.arc });
      const rest = { ...e };
      ['split', 'into', 'stagger', 'show', 'sort', 'by', 'desc', 'order', 'count', 'from', 'to', 'flow', 'text', 'arc', 'index'].forEach((k) => { delete rest[k]; });
      if (e.set != null || e.type != null) rest.text = e.text;
      if (Object.keys(rest).some((k) => !['at', 'i', 'dur', 'fade', 'stagger'].includes(k))) out.push(rest);
      return out;
    });

    const fx = h('div', { class: 'fx' });
    const camera = h('div', { class: 'camera' }, [wrap, fx]);
    const el = h('div', { class: 'scene scene-mech' }, [h('div', { class: 'clip' }, [camera])]);
    const rt = EV.events({ ...spec, events }, { root: wrap, camera, fx, cursor: spec.cursor != null, measure: ctx.measure });
    if (spec.mount) spec.mount(wrap, ctx);
    return {
      el,
      prepare: () => {
        rt.prepare();
        items.forEach((r) => r.prepare?.(ctx.measure));
      },
      render: (lt) => {
        rt.render(lt);
        items.forEach((r) => r.render?.(lt));
      },
      captionAt: rt.captionAt,
      kickerAt: rt.kickerAt,
    };
  });
})();
