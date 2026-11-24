#!/usr/bin/env python3
"""物理の ER 図 (erDiagram の SVG) 2 枚の差分を SVG の構造から求め、色付きの SVG と単一の HTML を出す。

使い方: python3 erd-diff.py <before.svg> <after.svg> <out_dir> --title "..." --base-label "..." [--date YYYY-MM-DD]
標準ライブラリだけで動く。読み取れない要素は標準エラーに出して続ける。
"""

import argparse
import datetime
import html
import math
import os
import re
import sys
from dataclasses import dataclass, field

GREEN = "#16a34a"
PURPLE = "#7c3aed"
RED = "#dc2626"
GREEN_BG = "#dcfce7"

WARNINGS: list[str] = []


def warn(msg: str) -> None:
    WARNINGS.append(msg)
    print(f"warning: {msg}", file=sys.stderr)


# ---------------------------------------------------------------- 読み取り


@dataclass
class Col:
    name: str
    type: str
    nullable: bool
    keys: tuple[str, ...]
    y: str

    def render(self) -> str:
        k = f"[{','.join(self.keys)}] " if self.keys else ""
        return f"{k}{self.type} {self.name}{'?' if self.nullable else ''}"

    def sig(self) -> tuple:
        return (self.type, self.nullable, self.keys)


@dataclass
class Table:
    id: str
    cols: dict[str, Col] = field(default_factory=dict)


@dataclass
class Rel:
    idx: int
    e1: str
    e2: str
    c1: str
    c2: str
    ident: str
    label: str
    points: list[tuple[float, float]]

    def pair(self) -> tuple[str, str]:
        return tuple(sorted((self.e1, self.e2)))

    def cards(self) -> tuple[str, str]:
        # 並べ替えた 2 表の順に多重度を揃える (向きが逆に書かれても同じ線として比べる)
        return (self.c1, self.c2) if self.e1 <= self.e2 else (self.c2, self.c1)

    def on_delete(self) -> str:
        # ラベルの末尾の on delete (「意味 (restrict)」か「restrict」だけ)
        m = re.search(r"(?:^|\()(restrict|cascade|set null|set default|no action)\)?$", self.label)
        return m.group(1) if m else "?"

    def struct(self) -> tuple:
        # 構造 = 多重度の組と on delete (と識別 / 非識別)。ラベルの文言は含めない
        return (self.cards(), self.on_delete(), self.ident)

    def sig(self) -> tuple:
        return (self.label, self.struct())

    def title(self) -> str:
        return f"{self.e1} -> {self.e2} ({self.label})"

    def detail(self) -> str:
        d = "" if self.ident == "true" else ", 非識別"
        return f"({self.label}) [{self.c1} / {self.c2}{d}]"


ENTITY_RE = re.compile(r'<g class="entity"[^>]*>.*?</g>', re.S)
TEXT_RE = re.compile(r"<text\b[^>]*>.*?</text>", re.S)
POLY_RE = re.compile(r"<polyline\b[^>]*/>")


def attr(tag: str, name: str) -> str | None:
    m = re.search(rf'\s{re.escape(name)}="([^"]*)"', tag)
    return html.unescape(m.group(1)) if m else None


def inner_text(t: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", re.sub(r"^<text\b[^>]*>|</text>$", "", t))).strip()


def parse_points(s: str | None) -> list[tuple[float, float]]:
    pts = []
    for p in (s or "").split():
        try:
            x, y = p.split(",")
            pts.append((float(x), float(y)))
        except ValueError:
            return []
    return pts


def parse_entity(block: str, src: str) -> Table | None:
    head = re.match(r"<g\b[^>]*>", block).group(0)
    tid = attr(head, "data-id")
    if not tid:
        warn(f"{src}: data-id の無い g.entity を飛ばした")
        return None
    table = Table(tid)
    rows: dict[str, list[str]] = {}
    for t in TEXT_RE.findall(block):
        y = attr(t, "y")
        if y is None:
            warn(f"{src}: {tid} の y の無い text を飛ばした: {inner_text(t)}")
            continue
        rows.setdefault(y, []).append(t)
    for y, ts in rows.items():
        keys, typ, name, other = [], None, None, []
        for t in ts:
            txt = inner_text(t)
            if 'font-size="13"' in t:
                continue  # 表の見出し
            if 'font-style="italic"' in t and txt == "(no attributes)":
                continue
            if 'font-size="9"' in t:
                keys.extend(k for k in re.split(r"[,\s]+", txt) if k)
            elif "mono" in t and 'text-anchor="end"' in t:
                name = txt
            elif "mono" in t:
                typ = txt
            else:
                other.append(txt)
        if not ts or all('font-size="13"' in t or 'font-style="italic"' in t for t in ts):
            continue
        if other:
            warn(f"{src}: {tid} の行 (y={y}) に読めない text: {other}")
        if name is None or typ is None:
            warn(f"{src}: {tid} の行 (y={y}) の型か列名が読めない (type={typ}, name={name})")
            continue
        nullable = name.endswith("?")
        bare = name[:-1] if nullable else name
        if bare in table.cols:
            warn(f"{src}: {tid}.{bare} が 2 回出た (後の行を使う)")
        table.cols[bare] = Col(bare, typ, nullable, tuple(sorted(keys)), y)
    return table


def parse_svg(svg: str, src: str) -> tuple[dict[str, Table], list[Rel]]:
    tables: dict[str, Table] = {}
    for block in ENTITY_RE.findall(svg):
        t = parse_entity(block, src)
        if t is None:
            continue
        if t.id in tables:
            warn(f"{src}: 表 {t.id} が 2 回出た (後のものを使う)")
        tables[t.id] = t
    rels: list[Rel] = []
    for i, p in enumerate(POLY_RE.findall(svg)):
        if 'class="er-relationship"' not in p:
            warn(f"{src}: er-relationship でない polyline (番号 {i}) を飛ばした")
            rels.append(None)
            continue
        e1, e2 = attr(p, "data-entity1"), attr(p, "data-entity2")
        if not e1 or not e2:
            warn(f"{src}: data-entity1 / data-entity2 の無い線 (番号 {i}) を飛ばした")
            rels.append(None)
            continue
        for e in (e1, e2):
            if e not in tables:
                warn(f"{src}: 線 {e1} -> {e2} の端 {e} が表に無い")
        rels.append(
            Rel(
                i,
                e1,
                e2,
                attr(p, "data-cardinality1") or "?",
                attr(p, "data-cardinality2") or "?",
                attr(p, "data-identifying") or "?",
                attr(p, "data-label") or "",
                parse_points(attr(p, "points")),
            )
        )
    if not tables:
        warn(f"{src}: g.entity が 1 つも無い")
    return tables, rels


# ---------------------------------------------------------------- 差分


@dataclass
class Diff:
    added_tables: list[str] = field(default_factory=list)
    removed_tables: list[str] = field(default_factory=list)
    added_cols: list[tuple[str, Col]] = field(default_factory=list)
    removed_cols: list[tuple[str, Col]] = field(default_factory=list)
    changed_cols: list[tuple[str, Col, Col]] = field(default_factory=list)
    added_rels: list[Rel] = field(default_factory=list)
    removed_rels: list[Rel] = field(default_factory=list)
    changed_rels: list[tuple[Rel, Rel]] = field(default_factory=list)
    relabeled_rels: list[tuple[Rel, Rel]] = field(default_factory=list)


def label_meaning(label: str) -> str:
    return re.split(r"、| \(", label, maxsplit=1)[0]


def diff_models(bt: dict[str, Table], br: list[Rel], at: dict[str, Table], ar: list[Rel]) -> Diff:
    d = Diff()
    d.added_tables = [t for t in at if t not in bt]
    d.removed_tables = [t for t in bt if t not in at]
    for tid, t in at.items():
        if tid not in bt:
            continue
        b = bt[tid]
        for cn, c in t.cols.items():
            if cn not in b.cols:
                d.added_cols.append((tid, c))
            elif b.cols[cn].sig() != c.sig():
                d.changed_cols.append((tid, b.cols[cn], c))
        for cn, c in b.cols.items():
            if cn not in t.cols:
                d.removed_cols.append((tid, c))

    def group(rels: list[Rel]) -> dict[tuple, list[Rel]]:
        g: dict[tuple, list[Rel]] = {}
        for r in rels:
            if r is not None:
                g.setdefault(r.pair(), []).append(r)
        return g

    bg, ag = group(br), group(ar)
    for pair in list(ag) + [p for p in bg if p not in ag]:
        bs, as_ = list(bg.get(pair, [])), list(ag.get(pair, []))
        # 1. 全く同じ線
        for a in list(as_):
            m = next((b for b in bs if b.sig() == a.sig()), None)
            if m:
                bs.remove(m)
                as_.remove(a)
        # 2. 構造が同じでラベルの文言だけが違う線 (色を付けず、別の区分に出す)。
        #    同じ 2 表の間に構造の同じ線が複数あるときは、ラベルの意味の部分が同じものを先に組にする
        for same in (lambda b, a: label_meaning(b.label) == label_meaning(a.label), lambda b, a: True):
            for a in list(as_):
                m = next((b for b in bs if b.struct() == a.struct() and same(b, a)), None)
                if m:
                    bs.remove(m)
                    as_.remove(a)
                    d.relabeled_rels.append((m, a))
        # 3. 同じラベルで構造 (多重度、on delete、識別) が変わった線
        for a in list(as_):
            m = next((b for b in bs if b.label == a.label), None)
            if m:
                bs.remove(m)
                as_.remove(a)
                d.changed_rels.append((m, a))
        # 4. ラベルの意味の部分 (最初の「、」か「 (」の前) が同じで構造が変わった線
        for a in list(as_):
            m = next((b for b in bs if label_meaning(b.label) == label_meaning(a.label)), None)
            if m:
                bs.remove(m)
                as_.remove(a)
                d.changed_rels.append((m, a))
        # 5. 同じ 2 表の間で残ったものは出てきた順に組にして、構造が変わった線とみなす
        while bs and as_:
            d.changed_rels.append((bs.pop(0), as_.pop(0)))
        d.added_rels.extend(as_)
        d.removed_rels.extend(bs)
    d.added_rels.sort(key=lambda r: r.idx)
    d.changed_rels.sort(key=lambda p: p[1].idx)
    d.relabeled_rels.sort(key=lambda p: p[1].idx)
    d.removed_rels.sort(key=lambda r: r.idx)
    return d


# ---------------------------------------------------------------- 色付け


def recolor_text(t: str, color: str, bold: bool = True) -> str:
    t = re.sub(r'fill="var\([^"]*\)"', f'fill="{color}"', t)
    return re.sub(r'font-weight="\d+"', 'font-weight="700"', t) if bold else t


def color_entity(block: str, status_table: str | None, row_status: dict[str, str]) -> str:
    rect_m = re.search(r"<rect\b[^>]*/>", block)
    if not rect_m:
        return block
    outer = rect_m.group(0)
    x, w = float(attr(outer, "x") or 0), float(attr(outer, "width") or 0)
    if status_table == "add":
        new_outer = re.sub(r'stroke="[^"]*"', f'stroke="{GREEN}"', outer)
        new_outer = re.sub(r'stroke-width="[^"]*"', 'stroke-width="3"', new_outer)
        block = block.replace(outer, new_outer, 1)
        rects = re.findall(r"<rect\b[^>]*/>", block)
        if len(rects) > 1:
            hdr = rects[1]
            block = block.replace(hdr, re.sub(r'fill="[^"]*"', f'fill="{GREEN_BG}"', hdr), 1)
        outer = new_outer
    colors = {"add": GREEN, "chg": PURPLE}

    def fix_text(m: re.Match) -> str:
        t = m.group(0)
        if status_table == "add" and 'font-size="13"' in t:
            return recolor_text(t, GREEN)
        st = row_status.get(attr(t, "y") or "")
        return recolor_text(t, colors[st]) if st else t

    block = TEXT_RE.sub(fix_text, block)
    # 行の背景の帯 (縮小表示でも色が見えるように)
    bands = "".join(
        f'\n  <rect x="{x + 1:.2f}" y="{float(y) - 11:.2f}" width="{w - 2:.2f}" height="22" fill="{colors[st]}" fill-opacity="0.14" />'
        for y, st in row_status.items()
        if status_table != "add"
    )
    if bands:
        block = block.replace(outer, outer + bands, 1)
    return block


def path_mid(pts: list[tuple[float, float]]) -> tuple[float, float]:
    if not pts:
        return (math.nan, math.nan)
    segs = [(a, b, math.dist(a, b)) for a, b in zip(pts, pts[1:])]
    half = sum(s[2] for s in segs) / 2
    for a, b, l in segs:
        if half <= l and l > 0:
            f = half / l
            return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
        half -= l
    return pts[-1]


def seg_dist(p: tuple[float, float], a: tuple[float, float], b: tuple[float, float]) -> float:
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / ((dx * dx + dy * dy) or 1.0)))
    return math.dist(p, (a[0] + t * dx, a[1] + t * dy))


def path_dist(p: tuple[float, float], pts: list[tuple[float, float]]) -> float:
    return min((seg_dist(p, a, b) for a, b in zip(pts, pts[1:])), default=math.dist(p, path_mid(pts)))


def num(tag: str, name: str) -> float:
    try:
        return float(attr(tag, name) or "nan")
    except ValueError:
        return math.nan


def colorize(svg: str, tables: dict[str, Table], rels: list[Rel], d: Diff) -> tuple[str, dict]:
    hits = {"tables": 0, "rows": 0, "lines": 0, "markers": 0, "labels": 0}
    rel_status: dict[int, str] = {r.idx: "add" for r in d.added_rels}
    rel_status.update({a.idx: "chg" for _, a in d.changed_rels})
    colors = {"add": GREEN, "chg": PURPLE}

    counter = iter(range(10**9))

    def fix_poly(m: re.Match) -> str:
        p = m.group(0)
        st = rel_status.get(next(counter))
        if not st:
            return p
        hits["lines"] += 1
        p = re.sub(r'stroke="[^"]*"', f'stroke="{colors[st]}"', p)
        return re.sub(r'stroke-width="[^"]*"', 'stroke-width="3"', p)

    svg = POLY_RE.sub(fix_poly, svg)

    added_tables = set(d.added_tables)
    row_status: dict[str, dict[str, str]] = {}
    for tid, c in d.added_cols:
        row_status.setdefault(tid, {})[c.y] = "add"
    for tid, _, c in d.changed_cols:
        row_status.setdefault(tid, {})[c.y] = "chg"

    def fix_entity(m: re.Match) -> str:
        block = m.group(0)
        tid = attr(re.match(r"<g\b[^>]*>", block).group(0), "data-id")
        ts = "add" if tid in added_tables else None
        rs = row_status.get(tid or "", {})
        if ts:
            hits["tables"] += 1
            rs = {c.y: "add" for c in tables[tid].cols.values()}
        hits["rows"] += len(rs) if not ts else 0
        return color_entity(block, ts, rs) if (ts or rs) else block

    svg = ENTITY_RE.sub(fix_entity, svg)

    # 線の端の多重度の印と、線のラベルは g.entity の後ろに並んでいる
    last = [m.end() for m in ENTITY_RE.finditer(svg)]
    cut = last[-1] if last else svg.find("<polyline")
    head, tail = svg[:cut], svg[cut:]
    live = [r for r in rels if r is not None and r.points]
    ends = [(r.idx, pt) for r in live for pt in (r.points[0], r.points[-1])]

    def fix_marker(m: re.Match) -> str:
        t = m.group(0)
        if t.startswith("<circle"):
            c = (num(t, "cx"), num(t, "cy"))
        else:
            c = ((num(t, "x1") + num(t, "x2")) / 2, (num(t, "y1") + num(t, "y2")) / 2)
        if any(math.isnan(v) for v in c) or not ends:
            return t
        idx, pt = min(ends, key=lambda e: math.dist(e[1], c))
        st = rel_status.get(idx)
        if not st or math.dist(pt, c) > 30:
            return t
        hits["markers"] += 1
        t = re.sub(r'stroke="[^"]*"', f'stroke="{colors[st]}"', t)
        return re.sub(r'stroke-width="[^"]*"', 'stroke-width="2"', t)

    tail = re.sub(r"<line\b[^>]*/>|<circle\b[^>]*/>", fix_marker, tail)

    by_label: dict[str, list[int]] = {}
    for r in live:
        by_label.setdefault(r.label, []).append(r.idx)

    def fix_label(m: re.Match) -> str:
        rect, gap, text = m.group(1), m.group(2), m.group(3)
        lab = inner_text(text)
        cands = by_label.get(lab, [])
        if not cands:
            warn(f"after: どの線のものか分からないラベル: {lab}")
            return m.group(0)
        pos = (num(text, "x"), num(text, "y"))
        # ラベルは線の上に載る (描画器が線の上に置く)。同じ文言の線のうち、ラベルの中心から最も近い線に結び付ける
        pts = {r.idx: r.points for r in live}
        idx = min(cands, key=lambda i: path_dist(pos, pts[i]) if not math.isnan(pos[0]) else 0)
        st = rel_status.get(idx)
        if not st:
            return m.group(0)
        hits["labels"] += 1
        rect = re.sub(r'stroke="[^"]*"', f'stroke="{colors[st]}"', rect)
        rect = re.sub(r'stroke-width="[^"]*"', 'stroke-width="1.5"', rect)
        # ラベルの箱の幅は元の太さで決まっているので、太字にしない (はみ出す)
        return rect + gap + recolor_text(text, colors[st], bold=False)

    tail = re.sub(r"(<rect\b[^>]*/>)(\s*)(<text\b[^>]*>.*?</text>)", fix_label, tail, flags=re.S)
    return head + tail, hits


# ---------------------------------------------------------------- 消したものの注記と SVG の凡例


def text_width(s: str, fs: float) -> float:
    return sum(fs * (1.0 if ord(ch) > 0x2E7F else 0.6) for ch in s)


def removed_lines(d: Diff, btables: dict[str, Table]) -> list[str]:
    out = [f"表 {t} (列 {len(btables[t].cols)})" for t in d.removed_tables]
    out += [f"列 {t}.{c.name} ({c.render()})" for t, c in d.removed_cols]
    out += [f"線 {r.title()}" for r in d.removed_rels]
    return out


def add_annotations(svg: str, items: list[str]) -> str:
    m = re.search(r"<svg\b[^>]*>", svg)
    root = m.group(0)
    vb = attr(root, "viewBox")
    try:
        vx, vy, vw, vh = (float(v) for v in vb.split())
    except (AttributeError, ValueError):
        warn("after: svg の viewBox が読めないので注記を付けない")
        return svg
    fs, title_fs, pad, lh = 26, 30, 24, 38
    y0 = vy + vh + 20
    parts = []
    # 凡例
    lx = vx + 40
    legend = [(GREEN, "緑 = 足した"), (PURPLE, "紫 = 変えた"), (RED, "赤の枠 = 消した (この図には無い)")]
    for color, label in legend:
        sw = (
            f'<rect x="{lx:.1f}" y="{y0 + 2:.1f}" width="44" height="24" rx="3" fill="#fef2f2" stroke="{color}" stroke-width="3" />'
            if color == RED
            else f'<rect x="{lx:.1f}" y="{y0 + 8:.1f}" width="44" height="14" fill="{color}" />'
        )
        parts.append(sw)
        parts.append(
            f'<text x="{lx + 56:.1f}" y="{y0 + 22:.1f}" font-size="{fs}" font-weight="700" fill="{color}">{html.escape(label)}</text>'
        )
        lx += 56 + text_width(label, fs) + 48
    y = y0 + 60
    total_w = lx
    if items:
        per_col = 14
        cols = [items[i : i + per_col] for i in range(0, len(items), per_col)]
        col_w = [max(text_width(s, fs) for s in c) + 40 for c in cols]
        title = f"消したもの ({len(items)} 件)"
        box_w = max(sum(col_w), text_width(title, title_fs)) + pad * 2
        box_h = pad * 2 + title_fs + 16 + lh * len(cols[0])
        bx = vx + 40
        parts.append(
            f'<rect x="{bx:.1f}" y="{y:.1f}" width="{box_w:.1f}" height="{box_h:.1f}" rx="6" fill="#fef2f2" stroke="{RED}" stroke-width="3" />'
        )
        parts.append(
            f'<text x="{bx + pad:.1f}" y="{y + pad + title_fs * 0.85:.1f}" font-size="{title_fs}" font-weight="700" fill="{RED}">{html.escape(title)}</text>'
        )
        cx = bx + pad
        for c, cw in zip(cols, col_w):
            for j, s in enumerate(c):
                ty = y + pad + title_fs + 16 + lh * j + fs * 0.9
                parts.append(
                    f'<text x="{cx:.1f}" y="{ty:.1f}" class="mono" font-size="{fs}" fill="{RED}">{html.escape(s)}</text>'
                )
            cx += cw
        y += box_h
        total_w = max(total_w, bx + box_w)
    new_h = y + 30 - vy
    new_w = max(vw, total_w + 40 - vx)
    new_root = re.sub(r'viewBox="[^"]*"', f'viewBox="{vx:g} {vy:g} {new_w:g} {new_h:g}"', root)
    new_root = re.sub(r'\swidth="[^"]*"', f' width="{new_w:g}"', new_root, count=1)
    new_root = re.sub(r'\sheight="[^"]*"', f' height="{new_h:g}"', new_root, count=1)
    svg = svg.replace(root, new_root, 1)
    band = f'<g class="erd-diff-notes">\n' + "\n".join(parts) + "\n</g>\n"
    i = svg.rfind("</svg>")
    return svg[:i] + band + svg[i:]


# ---------------------------------------------------------------- HTML

CSS = """:root { --bg: #f6f5f2; --fg: #1f2328; --muted: #59636e; --card: #ffffff; --border: #d8d6d0; --accent: #0969da; color-scheme: light }
@media (prefers-color-scheme: dark) { :root { --bg: #16181c; --fg: #e6e6e6; --muted: #9aa0a6; --card: #ffffff; --border: #3a3d42; --accent: #6cb6ff; color-scheme: dark } }
html { padding-top: env(safe-area-inset-top, 0px); padding-bottom: env(safe-area-inset-bottom, 0px) }
body { margin: 0; background: var(--bg); color: var(--fg); font-family: "Noto Sans JP", system-ui, sans-serif; font-size: 14px; padding-block: 24px; padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); line-height: 1.6 }
h1 { font-size: 1.4rem; margin: 0 0 4px; text-wrap: balance }
h2 { font-size: 1.1rem; margin: 0 0 4px }
.lead, .note, section > p { max-width: 65ch }
.lead { color: var(--muted); margin: 0 0 16px }
.note { color: var(--muted); font-size: .9rem; margin: 0 0 8px }
nav { display: flex; flex-wrap: wrap; gap: 8px 16px; margin-bottom: 16px }
nav a { color: var(--accent); text-decoration: none; font-size: .95rem }
section { margin-bottom: 36px }
table { border-collapse: collapse; margin: 8px 0; font-size: .9rem }
th, td { border: 1px solid var(--border); padding: 6px 10px; text-align: left; vertical-align: top }
th { background: color-mix(in srgb, var(--fg) 8%, var(--bg)); white-space: nowrap }
td.n { text-align: right; white-space: nowrap }
td ul { margin: 0; padding-left: 1.2em }
.tblwrap { overflow-x: auto }
.fig { background: var(--card); border: 1px solid var(--border); border-radius: 8px; overflow-x: auto; padding: 8px }
.fig svg { display: block; margin-inline: auto }
code { font-family: ui-monospace, "JetBrains Mono", monospace; font-size: .9em }
.sw { display: inline-block; width: 28px; height: 4px; margin-right: 8px; vertical-align: middle }
.box { display: inline-block; width: 24px; height: 12px; margin-right: 8px; vertical-align: middle; border: 2px solid #dc2626; background: #fef2f2 }
.add { color: #16a34a } .chg { color: #7c3aed } .del { color: #dc2626 } .lbl { color: var(--muted) }
summary { cursor: pointer; color: var(--accent) }
"""


def strip_import(svg: str) -> str:
    return re.sub(r"\s*@import url\([^)]*\);", "", svg)


def categories(d: Diff, btables: dict[str, Table], atables: dict[str, Table]) -> list[tuple[str, str, list[str]]]:
    def rel_chg(b: Rel, a: Rel) -> str:
        return f"{a.e1} -> {a.e2}: {b.detail()} -> {a.detail()}"

    return [
        ("足した表", "add", [f"{t} (列 {len(atables[t].cols)})" for t in d.added_tables]),
        ("足した列", "add", [f"{t}.{c.name} ({c.render()})" for t, c in d.added_cols]),
        ("変えた列", "chg", [f"{t}.{a.name}: {b.render()} -> {a.render()}" for t, b, a in d.changed_cols]),
        ("足した線", "add", [r.title() for r in d.added_rels]),
        ("変えた線", "chg", [rel_chg(b, a) for b, a in d.changed_rels]),
        ("消した表", "del", [f"{t} (列 {len(btables[t].cols)})" for t in d.removed_tables]),
        ("消した列", "del", [f"{t}.{c.name} ({c.render()})" for t, c in d.removed_cols]),
        ("消した線", "del", [r.title() for r in d.removed_rels]),
        ("ラベルの文言だけの変更 (構造は同じ)", "lbl", [f"{a.e1} -> {a.e2}: ({b.label}) -> ({a.label})" for b, a in d.relabeled_rels]),
    ]


def build_html(title: str, base_label: str, cats, diff_svg: str, before_svg: str, after_svg: str) -> str:
    e = html.escape
    rows = []
    for name, cls, items in cats:
        lst = "<ul>" + "".join(f"<li><code>{e(s)}</code></li>" for s in items) + "</ul>" if items else "なし"
        if items and cls == "lbl":
            lst = f"<details><summary>一覧を開く ({len(items)} 件。色は付けていない)</summary>{lst}</details>"
        rows.append(f'<tr><th class="{cls}">{e(name)}</th><td class="n">{len(items)}</td><td>{lst}</td></tr>')
    table = '<div class="tblwrap"><table><tr><th>区分</th><th>件数</th><th>一覧</th></tr>' + "".join(rows) + "</table></div>"
    return f"""<!DOCTYPE html>
<html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{e(title)}</title><style>{CSS}</style></head><body>
<h1>{e(title)}</h1>
<p class="lead">{e(base_label)}</p>
<nav><a href="#changes">変更の一覧</a><a href="#diff">差分 (色付き)</a><a href="#before">変更前</a><a href="#after">変更後</a><a href="#legend">凡例</a></nav>
<section id="changes"><h2>変更の一覧</h2>
<p class="note">列名を変えたものは、消した列と足した列の両方に出る。足した表と消した表の列は、列の区分には入れていない。線は多重度と on delete で比べ、ラベルの文言だけが違う線は末尾の「ラベルの文言だけの変更」に入れる (色は付けない)。</p>
{table}</section>
<section id="diff"><h2>差分 (変更後の図に色を付けたもの)</h2>
<p class="note">緑が足したもの、紫が変えたもの。消したものは変更後の図に無いので、図の下の赤い枠に一覧で書いた。</p>
<div class="fig">{strip_import(diff_svg)}</div></section>
<section id="before"><h2>変更前</h2><div class="fig">{strip_import(before_svg)}</div></section>
<section id="after"><h2>変更後</h2><div class="fig">{strip_import(after_svg)}</div></section>
<section id="legend"><h2>凡例</h2>
<p><span class="sw" style="background:{GREEN}"></span><strong class="add">緑</strong> = 足した表、足した列 (表の中の行)、足した線</p>
<p><span class="sw" style="background:{PURPLE}"></span><strong class="chg">紫</strong> = 変えた列 (型、NULL 可 (列名の末尾の ?)、PK / FK / UK の印のどれかが変わった)、変えた線 (同じ 2 表の間で多重度か on delete が変わった。ラベルの文言だけの変更は色を付けず、変更の一覧の末尾の区分に出す)</p>
<p><span class="box"></span><strong class="del">赤の枠</strong> = 消した表、列、線 (変更後の図には無いので、図の下に一覧で書いた)</p>
</section>
</body></html>
"""


# ---------------------------------------------------------------- main


def main() -> int:
    ap = argparse.ArgumentParser(description="物理の ER 図 (erDiagram の SVG) 2 枚の差分を出す")
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("out_dir")
    ap.add_argument("--title", default="ER 図の差分")
    ap.add_argument("--base-label", default="")
    ap.add_argument("--date", default=datetime.date.today().isoformat(), help="HTML のファイル名の日付 (既定は今日)")
    a = ap.parse_args()

    before = open(a.before, encoding="utf-8").read()
    after = open(a.after, encoding="utf-8").read()
    bt, br = parse_svg(before, "before")
    at, ar = parse_svg(after, "after")
    d = diff_models(bt, br, at, ar)

    colored, hits = colorize(after, at, ar, d)
    colored = add_annotations(colored, removed_lines(d, bt))

    os.makedirs(a.out_dir, exist_ok=True)
    p_final = os.path.join(a.out_dir, "erd-all-final.svg")
    p_diff = os.path.join(a.out_dir, "erd-all-diff.svg")
    p_html = os.path.join(a.out_dir, f"erd-diff-{a.date}.html")
    open(p_final, "w", encoding="utf-8").write(after)
    open(p_diff, "w", encoding="utf-8").write(colored)
    cats = categories(d, bt, at)
    open(p_html, "w", encoding="utf-8").write(build_html(a.title, a.base_label, cats, colored, before, after))

    print(f"before: 表 {len(bt)} / 列 {sum(len(t.cols) for t in bt.values())} / 線 {sum(r is not None for r in br)}")
    print(f"after : 表 {len(at)} / 列 {sum(len(t.cols) for t in at.values())} / 線 {sum(r is not None for r in ar)}")
    for name, _, items in cats:
        print(f"{name}: {len(items)}")
        for s in items:
            print(f"  {s}")
    print(f"色付け: {hits}")
    print(f"読み取れなかった要素: {len(WARNINGS)}")
    print(f"出力: {p_final}, {p_diff}, {p_html}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
