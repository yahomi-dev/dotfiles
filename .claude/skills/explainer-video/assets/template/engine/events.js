// events.js — ui / mech / arch 共通のイベント実行機。
// { at, ... } の並びから「時刻 lt の状態」を毎コマ組み立て直す (前のコマに依存しないので、どの t から撮っても同じ絵になる)。
// 語彙 (references/timeline.md):
//   show / hide      要素を出す / 消す (fade 秒、既定 0.35)
//   move             カーソルを要素まで動かす (dur 秒、既定 0.6)
//   click            at の時刻にカーソルが要素に着いて押す (直前 0.6 秒で移動してくる)
//   type             要素に text を cps 文字/秒で打ち込む (既定 18)
//   set / cls / mark / unmark  文字の差し替え / class の付け外し / 強調
//   zoom             カメラ (数値 = その要素へ寄る倍率、'reset'、{ to, scale, x, y, dur, delay })
//   caption / kicker 字幕と小見出しの差し替え (core.js が読む)
(() => {
  const { W, H, CONTENT_H, clamp, ramp, lerp, easeInOut, easeOut, h, ids } = EV;
  // カメラの視野は字幕の帯を除いた 1600x730。ズームしても画面が字幕に重ならない
  const VH = CONTENT_H;
  const SHOW = 0.35;
  const MOVE = 0.6;
  const ZOOM = 0.7;
  const CPS = 18;
  const CURSOR = '<svg viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg"><path d="M4 2 L4 23 L9.6 17.8 L13.4 26.4 L17.2 24.7 L13.4 16.4 L21 16.4 Z" fill="#fff" stroke="#111" stroke-width="1.8" stroke-linejoin="round"/></svg>';
  const TARGET_KEYS = ['show', 'hide', 'move', 'click', 'type', 'set', 'cls', 'mark', 'unmark'];

  EV.events = (spec, env) => {
    // env: { root: data-id を探す範囲, camera: ズームを掛ける要素, fx: 波紋とカーソルを置く層, cursor: カーソルを出すか, measure(el) -> 舞台座標の矩形 }
    const evs = (spec.events || []).map((e, i) => ({ ...e, i })).sort((a, b) => a.at - b.at || a.i - b.i);
    const find = (id) => {
      const el = env.root.querySelector(`[data-id="${id}"]`);
      if (!el) console.warn(`data-id not found: ${id}`);
      return el;
    };

    // 触る要素の初期状態 (class と中身) を控えておき、毎コマそこから組み立て直す
    const base = new Map();
    const remember = (el) => {
      if (el && !base.has(el)) base.set(el, { html: el.innerHTML, cls: el.className });
      return el;
    };
    evs.forEach((e) => TARGET_KEYS.forEach((k) => {
      if (e[k] == null) return;
      ids(e[k]).forEach((id) => remember(find(id)));
    }));

    // ---- 表示 / 非表示: 最初の出来事が show なら初期は隠す。data-hidden も隠す ----
    const vis = new Map();
    const visEntry = (el, init) => {
      if (!vis.has(el)) vis.set(el, { init, list: [] });
      return vis.get(el);
    };
    evs.forEach((e) => [['show', true], ['hide', false]].forEach(([k, on]) => {
      if (e[k] == null) return;
      ids(e[k]).forEach((id) => {
        const el = find(id);
        if (el) visEntry(el, on ? 0 : 1).list.push({ at: e.at, on, dur: e.fade ?? SHOW });
      });
    }));
    env.root.querySelectorAll('[data-hidden]').forEach((el) => { visEntry(remember(el), 0).init = 0; });
    const visState = (v, lt) => v.list.reduce((st, x) => {
      if (lt < x.at) return st;
      const k = easeOut(ramp(lt, x.at, x.at + x.dur));
      return x.on ? { a: k, rise: (1 - k) * 10 } : { a: 1 - k, rise: 0 };
    }, { a: v.init, rise: 0 });

    // ---- 文字: set と type を時刻順に重ねる ----
    const textEvs = evs.filter((e) => e.set != null || e.type != null).map((e) => ({
      at: e.at,
      el: find(e.set ?? e.type),
      chars: Array.from(String(e.text ?? '')),
      typed: e.type != null,
      cps: e.cps ?? CPS,
    })).filter((e) => e.el);
    const textEls = new Set(textEvs.map((e) => e.el));

    const mods = evs.filter((e) => e.cls != null || e.mark != null || e.unmark != null);
    const clicks = evs.filter((e) => e.click != null).map((e) => ({ at: e.at, el: find(e.click), e, pos: null }));

    // ---- 位置 (prepare で測る: フォント読み込み後、カメラが等倍のとき) ----
    const rects = new Map();
    const rect = (id) => {
      if (!rects.has(id)) {
        const el = find(id);
        rects.set(id, el ? env.measure(el) : null);
      }
      return rects.get(id);
    };
    const center = (id, e = {}) => {
      const r = rect(id);
      return r ? { x: r.x + r.w / 2 + (e.dx ?? 0), y: r.y + r.h / 2 + (e.dy ?? 0) } : null;
    };
    const cursorInit = { x: spec.cursor?.x ?? W * 0.78, y: spec.cursor?.y ?? H * 0.74 };
    const camInit = { cx: W / 2, cy: VH / 2, s: 1 };
    const segs = [];
    const cams = [];

    const prepare = () => {
      rects.clear();
      segs.length = 0;
      cams.length = 0;
      // カーソルの区間: move は at から dur 秒かけて着く。click は at に着く (直前 dur 秒で動いてくる)
      evs.filter((e) => e.move != null || e.click != null).reduce((prev, e) => {
        const to = center(e.move ?? e.click, e);
        if (!to) return prev;
        const dur = e.dur ?? MOVE;
        const t1 = e.move != null ? e.at + dur : e.at;
        const same = Math.abs(to.x - prev.pos.x) < 1 && Math.abs(to.y - prev.pos.y) < 1;
        if (same) return { end: Math.max(prev.end, t1), pos: prev.pos };
        const t0 = Math.min(Math.max(prev.end, t1 - dur), t1 - 0.05);
        segs.push({ t0, t1, to });
        return { end: t1, pos: to };
      }, { end: -Infinity, pos: cursorInit });
      // カメラの区間
      evs.filter((e) => e.zoom != null).forEach((e) => {
        const z = e.zoom;
        const obj = typeof z === 'object' ? z : {};
        const reset = z === 'reset' || z === 1;
        const s = reset ? 1 : typeof z === 'number' ? z : (obj.scale ?? 1.6);
        const id = obj.to ?? e.click ?? e.move ?? e.type;
        const c = !reset && id != null ? center(id) : null;
        const hw = W / (2 * s);
        const hh = VH / (2 * s);
        const cx = reset ? W / 2 : (obj.x ?? (c ? c.x : W / 2));
        const cy = reset ? VH / 2 : (obj.y ?? (c ? c.y : VH / 2));
        const t0 = e.at + (obj.delay ?? 0);
        cams.push({ t0, t1: t0 + (obj.dur ?? ZOOM), to: { cx: clamp(cx, hw, W - hw), cy: clamp(cy, hh, VH - hh), s } });
      });
      clicks.forEach((c) => { c.pos = c.el ? center(c.e.click, c.e) : null; });
    };

    const cursorAt = (lt) => segs.reduce((p, s) => {
      if (lt >= s.t1) return s.to;
      if (lt < s.t0) return p;
      const k = easeInOut(ramp(lt, s.t0, s.t1));
      return { x: lerp(p.x, s.to.x, k), y: lerp(p.y, s.to.y, k) };
    }, cursorInit);
    const camAt = (lt) => cams.reduce((p, s) => {
      if (lt >= s.t1) return s.to;
      if (lt < s.t0) return p;
      const k = easeInOut(ramp(lt, s.t0, s.t1));
      return { cx: lerp(p.cx, s.to.cx, k), cy: lerp(p.cy, s.to.cy, k), s: lerp(p.s, s.to.s, k) };
    }, camInit);

    const cursorEl = env.cursor ? h('div', { class: 'cursor', html: CURSOR }) : null;

    const render = (lt) => {
      // 1) class と中身を初期状態に戻す
      base.forEach((b, el) => { el.className = b.cls; });
      textEls.forEach((el) => { el.innerHTML = base.get(el).html; });

      // 2) 表示 / 非表示
      const tf = new Map();
      vis.forEach((v, el) => {
        const st = visState(v, lt);
        el.style.opacity = st.a;
        if (st.rise > 0.01) tf.set(el, `translateY(${st.rise.toFixed(2)}px)`);
      });

      // 3) 文字 (set / type)
      textEvs.forEach((e) => {
        if (lt < e.at) return;
        const n = e.typed ? Math.min(e.chars.length, Math.floor((lt - e.at) * e.cps)) : e.chars.length;
        e.el.textContent = e.chars.slice(0, n).join('');
        if (!e.typed) return;
        if (n > 0) e.el.classList.add('typed');
        const end = e.at + e.chars.length / e.cps;
        if (lt < end + 0.8 && Math.floor(lt * 2.5) % 2 === 0) e.el.append(h('span', { class: 'caret' }));
      });

      // 4) class の付け外し
      mods.forEach((e) => {
        if (lt < e.at) return;
        if (e.cls != null) ids(e.cls).forEach((id) => {
          const el = find(id);
          if (!el) return;
          ids(e.add ?? []).forEach((c) => el.classList.add(c));
          ids(e.remove ?? []).forEach((c) => el.classList.remove(c));
        });
        if (e.mark != null) ids(e.mark).forEach((id) => find(id)?.classList.add('mark'));
        if (e.unmark != null) ids(e.unmark).forEach((id) => find(id)?.classList.remove('mark'));
      });

      // 5) クリック: 押し込みと波紋
      env.fx.innerHTML = '';
      clicks.forEach((c) => {
        const k = lt - c.at;
        if (k < 0 || !c.pos) return;
        if (k < 0.18 && c.el) c.el.classList.add('pressed');
        if (k < 0.5) {
          const q = k / 0.5;
          const r = lerp(8, 46, easeOut(q));
          env.fx.append(h('div', { class: 'ripple', style: { left: `${c.pos.x}px`, top: `${c.pos.y}px`, width: `${r * 2}px`, height: `${r * 2}px`, opacity: String(1 - q) } }));
        }
      });
      tf.forEach((v, el) => { el.style.transform = v; });
      vis.forEach((v, el) => { if (!tf.has(el)) el.style.transform = ''; });

      // 6) カーソル
      if (cursorEl && (segs.length || spec.cursor)) {
        const p = cursorAt(lt);
        const press = clicks.reduce((m, c) => {
          const k = lt - c.at;
          return k >= 0 && k < 0.2 ? Math.max(m, Math.sin(Math.PI * (k / 0.2))) : m;
        }, 0);
        cursorEl.style.left = `${p.x}px`;
        cursorEl.style.top = `${p.y}px`;
        cursorEl.style.transform = `translate(-3px, -2px) scale(${1 - 0.18 * press})`;
        env.fx.append(cursorEl);
      }

      // 7) カメラ
      if (env.camera) {
        const c = camAt(lt);
        env.camera.style.transform = `translate(${(W / 2 - c.cx * c.s).toFixed(2)}px, ${(VH / 2 - c.cy * c.s).toFixed(2)}px) scale(${c.s.toFixed(4)})`;
      }
    };

    const captionAt = (lt) => evs.reduce((r, e) => (e.caption != null && lt >= e.at ? { text: e.caption, since: e.at } : r), null);
    const kickerAt = (lt) => evs.reduce((r, e) => (e.kicker != null && lt >= e.at ? e.kicker : r), null);

    return { prepare, render, captionAt, kickerAt, rect, find };
  };
})();
