// core.js — TIMELINE (timeline.js) を受け取り、場面を順に並べて時刻 t の絵を作る。
// t が同じなら必ず同じ絵になる (乱数も実時間も使わない)。録画 (tools/render.mjs) は VIDEO.render(t) を 1 コマずつ呼ぶ。
// ふつうに開くとループ再生、?t=3.2 でその時刻に止める (時刻表示つき)、?render で録画用 (自動再生しない)。
(() => {
  const TL = window.TIMELINE;
  if (!TL || !Array.isArray(TL.scenes) || !TL.scenes.length) throw new Error('timeline.js に window.TIMELINE = { scenes: [...] } を書いてください');
  const { W, H, h, ramp, easeOut, clamp, registry } = EV;

  const theme = {
    bg: '#0b0d12', dot: '#1b2130', card: '#121722', fg: '#e8ecf4', dim: '#8b95a7', accent: '#22d3ee', edge: '#2a3245',
    font: "'Noto Sans JP', 'Noto Sans CJK JP', 'Hiragino Sans', 'Yu Gothic UI', sans-serif",
    mono: "'JetBrains Mono', 'Noto Sans Mono CJK JP', Consolas, monospace",
    ...(TL.theme || {}),
  };
  const stage = document.getElementById('stage');
  Object.entries(theme).forEach(([k, v]) => stage.style.setProperty(`--${k}`, v));
  stage.append(h('div', { class: 'bg-dots' }), h('div', { class: 'bg-vig' }));

  // ---- 時間割: 場面を順に並べる。場面の切り替えは XF 秒のクロスフェード。最後は FADE 秒で空に戻る (最初のコマも空なのでループが継ぎ目なし) ----
  const XF = 0.4;
  const FADE = 0.6;
  const scenes = TL.scenes.reduce((acc, s, i) => {
    const t0 = acc.length ? acc.at(-1).t1 : 0;
    const dur = s.dur ?? 4;
    return [...acc, { ...s, i, dur, t0, t1: t0 + dur }];
  }, []);
  const DUR = scenes.at(-1).t1 + FADE;

  // 小見出しの自動番号: ui = 操作 n、mech / arch = 仕組み n (kicker を書けばそちらが優先)
  const LABELS = { ui: TL.labels?.ui ?? '操作', mech: TL.labels?.mech ?? '仕組み', arch: TL.labels?.arch ?? '仕組み' };
  scenes.reduce((counts, s) => {
    const lab = LABELS[s.kind];
    if (s.kicker != null || !lab) return counts;
    const n = (counts[lab] || 0) + 1;
    s.kicker = `${lab} ${n}`;
    return { ...counts, [lab]: n };
  }, {});
  const steps = scenes.filter((s) => !['title', 'outro'].includes(s.kind));

  // 要素の矩形を舞台座標 (1600x900) で測る。プレビュー時は舞台が縮小されているので割り戻す
  const measure = (el, base = stage) => {
    const r = el.getBoundingClientRect();
    const b = base.getBoundingClientRect();
    const k = stage.getBoundingClientRect().width / W;
    return { x: (r.left - b.left) / k, y: (r.top - b.top) / k, w: r.width / k, h: r.height / k };
  };
  const ctx = { theme, measure, W, H };

  // ---- title / outro / custom ----
  const titleScene = (spec) => {
    const bar = h('div', { class: 'bar' });
    const h1 = h('h1', { html: spec.html ?? EV.esc(spec.title ?? '') });
    const p = spec.subtitle ? h('p', { text: spec.subtitle }) : null;
    const el = h('div', { class: 'scene' }, [h('div', { class: `title-scene${spec.kind === 'outro' ? ' outro-scene' : ''}` }, [bar, h1, p])]);
    const render = (lt) => [[bar, 0], [h1, 0.15], [p, 0.35]].forEach(([e, d]) => {
      if (!e) return;
      const k = easeOut(ramp(lt, d, d + 0.6));
      e.style.opacity = k;
      e.style.transform = `translateY(${((1 - k) * 16).toFixed(2)}px)`;
    });
    return { el, render };
  };
  registry.title = titleScene;
  registry.outro = titleScene;
  registry.custom = (spec) => {
    const camera = h('div', { class: 'camera' });
    const fx = h('div', { class: 'fx' });
    const el = h('div', { class: 'scene scene-custom' }, [h('div', { class: 'clip' }, [camera])]);
    const api = spec.mount ? spec.mount(camera, ctx) : undefined;
    camera.append(fx);
    const rt = EV.events(spec, { root: camera, camera, fx, cursor: spec.cursor != null, measure });
    return {
      el,
      prepare: () => {
        rt.prepare();
        spec.prepare?.(camera, ctx, api);
      },
      render: (lt) => {
        rt.render(lt);
        spec.render?.(lt, camera, ctx, api);
      },
      captionAt: rt.captionAt,
      kickerAt: rt.kickerAt,
    };
  };

  scenes.forEach((s) => {
    const build = registry[s.kind];
    if (!build) throw new Error(`unknown scene kind: ${s.kind} (title / ui / mech / arch / outro / custom)`);
    s.inst = build(s, ctx);
    stage.append(s.inst.el);
  });

  // ---- 常時パネル (カメラの外、字幕の上)。履歴の図や地図など、場面をまたいで見せ続けるもの。TIMELINE.panel = { mount, render } ----
  // 場面に panel: false を書くとその場面では消える。場面の panel: {...} は render の引数 scene.panel として渡る (中身は自由)
  const panelEl = TL.panel ? h('div', { class: 'panel' }) : null;
  const panelApi = panelEl ? TL.panel.mount?.(panelEl, ctx, scenes) : undefined;
  if (panelEl) stage.append(panelEl);

  // ---- 字幕 (カメラの外) ----
  const kicker = h('div', { class: 'kicker' });
  const caption = h('div', { class: 'caption' });
  const dots = steps.map(() => h('span', { class: 'dot' }));
  const subs = h('div', { class: 'subs' }, [kicker, caption, h('div', { class: 'dots' }, dots)]);
  const stamp = h('div', { class: 'stamp' });
  stage.append(subs, stamp);

  const alphaOf = (s, t) => (s.transition === 'cut'
    ? (t >= s.t0 && t < s.t1 ? 1 : 0)
    : easeOut(ramp(t, s.t0, s.t0 + XF)) * (1 - ramp(t, s.t1, s.t1 + XF)));

  const render = (t, opt = {}) => {
    const tt = clamp(t, 0, DUR);
    scenes.forEach((s) => {
      const a = alphaOf(s, tt);
      s.inst.el.style.opacity = a.toFixed(3);
      s.inst.el.style.visibility = a > 0 ? 'visible' : 'hidden';
      if (a > 0) s.inst.render(tt - s.t0, tt);
    });

    const cur = scenes.find((s) => tt >= s.t0 && tt < s.t1);
    const lt = cur ? tt - cur.t0 : 0;
    if (panelEl) {
      const a = Math.min(1, scenes.reduce((sum, s) => sum + (s.panel === false ? 0 : alphaOf(s, tt)), 0));
      panelEl.style.opacity = a.toFixed(3);
      if (a > 0) TL.panel.render?.(tt, panelEl, ctx, { scene: cur, lt, scenes, api: panelApi });
    }
    const capState = cur ? (cur.inst.captionAt?.(lt) ?? (cur.caption != null ? { text: cur.caption, since: 0 } : null)) : null;
    const chars = Array.from(capState?.text ?? '');
    const since = lt - (capState?.since ?? 0);
    caption.textContent = chars.slice(0, Math.round(ramp(since, 0.1, 0.1 + chars.length * 0.035) * chars.length)).join('');
    const sceneFade = cur ? easeOut(ramp(lt, 0, 0.3)) * (1 - ramp(lt, cur.dur - 0.25, cur.dur)) : 0;
    caption.style.opacity = (easeOut(ramp(since, 0, 0.15)) * sceneFade).toFixed(3);
    const kick = cur ? (cur.inst.kickerAt?.(lt) ?? cur.kicker ?? '') : '';
    kicker.textContent = kick;
    kicker.style.color = cur?.color ?? theme.accent;
    kicker.style.opacity = sceneFade.toFixed(3);
    const stepIdx = cur ? steps.indexOf(cur) : -1;
    const dotsOn = cur?.kind === 'outro';
    dots.forEach((d, i) => { d.className = `dot${dotsOn || i <= stepIdx ? ' on' : ''}`; });
    subs.querySelector('.dots').style.opacity = cur && cur.kind !== 'title' ? '1' : '0';

    stamp.textContent = opt.stamp ? `t=${tt.toFixed(2)}s` : '';
  };

  // ---- プレビューでは舞台を窓に合わせて縮小する (録画時は viewport = 1600x900 なので等倍) ----
  const fit = () => {
    const k = Math.min(innerWidth / W, innerHeight / H);
    stage.style.transform = `scale(${k})`;
  };
  addEventListener('resize', fit);
  fit();

  const firstUi = scenes.find((s) => s.kind === 'ui') ?? scenes[0];
  window.VIDEO = {
    ready: false,
    duration: DUR,
    fps: TL.fps ?? 30,
    posterTime: TL.poster ?? firstUi.t0 + Math.min(1.5, firstUi.dur / 2),
    render,
    phases: scenes.map((s) => ({ kind: s.kind, id: s.id ?? '', t0: +s.t0.toFixed(2), t1: +s.t1.toFixed(2), caption: [s.kicker, s.caption ?? s.title ?? ''].filter(Boolean).join(': ') })),
  };

  // ---- 起動: フォントを読み込んでから位置を測り、ready にする ----
  const q = new URLSearchParams(location.search);
  requestAnimationFrame(async () => {
    const fam = theme.font.split(',')[0].trim();
    const mono = theme.mono.split(',')[0].trim();
    await Promise.all([`400 20px ${fam}`, `700 20px ${fam}`, `900 20px ${fam}`, `700 20px ${mono}`].map((f) => document.fonts.load(f).catch(() => [])));
    await document.fonts.ready;
    scenes.forEach((s) => s.inst.prepare?.());
    render(0);
    VIDEO.ready = true;
    if (q.has('render')) return;
    if (q.has('t')) {
      render(Number(q.get('t')), { stamp: true });
      return;
    }
    const start = performance.now();
    const loop = () => {
      render(((performance.now() - start) / 1000) % DUR);
      requestAnimationFrame(loop);
    };
    loop();
  });
})();
