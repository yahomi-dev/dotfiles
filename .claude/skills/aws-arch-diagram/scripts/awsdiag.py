"""draw.io 風の AWS 構成図を SVG 文字列として組み立て、HTML ページと図ごとの standalone HTML / SVG を書き出すヘルパ。

使い方は SKILL.md と references/example-static-site.py を参照。
座標は viewBox の単位 (px 相当) で直接指定する。レイアウトの決め方は references/style-guide.md。
"""

from __future__ import annotations

import base64
import html
import os
import pathlib
import re

SKILL_DIR = pathlib.Path(__file__).resolve().parent.parent
# 任意: ここに置いた SVG を公式パッケージより先に使う (公式のアイコンのコピーなので git 管理外)
DEFAULT_ICON_DIR = SKILL_DIR / "assets" / "icons"
# AWS 公式 Icon package (SVG のみ) の保存先。fetch_icons.sh / find_icon.sh と同じ
OFFICIAL_PACKAGE_DIR = pathlib.Path(
    os.environ.get("AWS_ICONS_DIR")
    or pathlib.Path(os.environ.get("XDG_CACHE_HOME") or pathlib.Path.home() / ".cache") / "aws-architecture-icons"
)

FONT_LINK = (
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
    "family=IBM+Plex+Sans+JP:wght@400;500;700&family=IBM+Plex+Mono:wght@400;500&display=swap\">"
)
FONT_IMPORT = (
    '@import url("https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+JP:wght@400;500;700'
    '&amp;family=IBM+Plex+Mono:wght@400;500&amp;display=swap");'
)

# よく使うアイコン。key -> (ファイル名, viewBox の一辺)。
# 公式パッケージの命名: Arch_*_64.svg は viewBox 80、Res_*_48.svg は 48、グループ用 *_32.svg は 40
ICONS: dict[str, tuple[str, int]] = {
    "route53": ("Arch_Amazon-Route-53_64.svg", 80),
    "acm": ("Arch_AWS-Certificate-Manager_64.svg", 80),
    "cloudfront": ("Arch_Amazon-CloudFront_64.svg", 80),
    "s3": ("Arch_Amazon-Simple-Storage-Service_64.svg", 80),
    "iam": ("Arch_AWS-Identity-and-Access-Management_64.svg", 80),
    "cfn": ("Arch_AWS-CloudFormation_64.svg", 80),
    "ssmsvc": ("Arch_AWS-Systems-Manager_64.svg", 80),
    "bucket": ("Res_Amazon-Simple-Storage-Service_Bucket_48.svg", 48),
    "cffunc": ("Res_Amazon-CloudFront_Functions_48.svg", 48),
    "key": ("Res_AWS-Identity-Access-Management_Long-Term-Security-Credential_48.svg", 48),
    "stack": ("Res_AWS-CloudFormation_Stack_48.svg", 48),
    "ssm": ("Res_AWS-Systems-Manager_Parameter-Store_48.svg", 48),
    "cloud": ("AWS-Cloud_32.svg", 40),
    "region": ("Region_32.svg", 40),
    "users": ("Res_Users_48_Light.svg", 48),
}


def register(key: str, filename: str, size: int | None = None) -> None:
    """公式パッケージ内のファイル名でアイコンを追加する。size 省略時はファイル名の規約から推定する。"""
    if size is None:
        size = 80 if "_64" in filename else 40 if "_32" in filename else 48

    ICONS[key] = (filename, size)


def _find_icon_file(filename: str) -> pathlib.Path:
    candidate = DEFAULT_ICON_DIR / filename

    if candidate.exists():
        return candidate

    for found in OFFICIAL_PACKAGE_DIR.rglob(filename):
        return found

    raise FileNotFoundError(
        f"{filename} が {DEFAULT_ICON_DIR} にも {OFFICIAL_PACKAGE_DIR} にも無い。"
        "公式パッケージが無ければ scripts/fetch_icons.sh で取得し、ファイル名は scripts/find_icon.sh で探して register する"
    )


def data_uri(key: str) -> str:
    filename, _ = ICONS[key]
    path = _find_icon_file(filename)
    mime = "image/svg+xml" if path.suffix == ".svg" else "image/png"
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode()}"


def symbols(keys: list[str] | None = None) -> str:
    """<symbol id="ic-<key>"> の列。keys 省略時は登録済み全部 (使わないものも含めて軽い)。"""
    out = []

    for key in keys or list(ICONS):
        _, size = ICONS[key]
        out.append(
            f'<symbol id="ic-{key}" viewBox="0 0 {size} {size}"><image href="{data_uri(key)}" width="{size}" height="{size}"/></symbol>'
        )

    return "\n".join(out)


def e(s: str) -> str:
    return html.escape(s, quote=False)


def use(key: str, x: float, y: float, size: float, cls: str | None = None) -> str:
    """アイコンを (x, y) 左上、一辺 size で置く。"""
    c = f' class="{cls}"' if cls else ""
    return f'<use{c} href="#ic-{key}" x="{x}" y="{y}" width="{size}" height="{size}"/>'


def text(x: float, y: float, s: str, cls: str = "t", anchor: str | None = None) -> str:
    a = f' text-anchor="{anchor}"' if anchor else ""
    return f'<text class="{cls}" x="{x}" y="{y}"{a}>{e(s)}</text>'


def lines(x: float, y0: float, items: list[tuple[str, str]], step: float = 14) -> str:
    """(class, 文字列) の列を縦に並べる。詳細版の説明ブロック用。"""
    return "\n".join(text(x, y0 + i * step, s, cls) for i, (cls, s) in enumerate(items))


def label2(cx: float, y: float, main: str, sub: str | None = None) -> str:
    """アイコン下の中央寄せ 2 行ラベル (簡易版用)。"""
    out = [text(cx, y, main, "sl", "middle")]

    if sub:
        out.append(text(cx, y + 13, sub, "sls", "middle"))

    return "\n".join(out)


# ---- グループ枠 (公式の表記に合わせる) ----


def cloud_frame(x: float, y: float, w: float, h: float, sub: str = "", title: str = "AWS Cloud") -> str:
    """AWS Cloud: 黒の実線 + 左上に雲アイコン。"""
    out = [
        f'<rect class="cloud" x="{x}" y="{y}" width="{w}" height="{h}" rx="4"/>',
        use("cloud", x + 2, y + 2, 26),
        text(x + 36, y + 20, title, "tb"),
    ]

    if sub:
        out.append(text(x + 116, y + 20, sub, "ts"))

    return "\n".join(out)


def region_frame(x: float, y: float, w: float, h: float, title: str, sub: str = "") -> str:
    """Region: 青緑の破線 + 旗アイコン。"""
    out = [
        f'<rect class="region" x="{x}" y="{y}" width="{w}" height="{h}" rx="4"/>',
        use("region", x + 4, y + 4, 24),
        text(x + 34, y + 20, title, "tb"),
    ]

    if sub:
        out.append(text(x + 192, y + 20, sub, "ts"))

    return "\n".join(out)


def manual_box(x: float, y: float, w: float, h: float, title: str) -> str:
    """IaC 管理外 (手動管理) のまとまり: 薄い塗り + 灰色の破線。"""
    return "\n".join(
        [
            f'<rect class="manual" x="{x}" y="{y}" width="{w}" height="{h}" rx="4"/>',
            text(x + 12, y + 16, title, "te"),
        ]
    )


def stack_band(x: float, y: float, w: float, h: float, name: str, env: str = "", env_x: float | None = None) -> str:
    """詳細版のスタック帯: 白地 + 灰の実線 + 左上にスタックアイコンと名前。"""
    out = [
        f'<rect class="stack" x="{x}" y="{y}" width="{w}" height="{h}" rx="6"/>',
        use("stack", x + 8, y + 6, 20),
        text(x + 34, y + 21, name, "tb"),
    ]

    if env:
        out.append(text(env_x if env_x is not None else x + 580, y + 21, env, "ts"))

    return "\n".join(out)


def sbox(x: float, y: float, w: float, h: float, name: str) -> str:
    """簡易版のグループ枠 (draw.io の Region 風、青の破線 + 小アイコン + 名前)。"""
    return "\n".join(
        [
            f'<rect class="sbox" x="{x}" y="{y}" width="{w}" height="{h}" rx="4"/>',
            use("stack", x + 10, y + 8, 16),
            text(x + 32, y + 21, name, "stag"),
        ]
    )


# ---- 線 ----


def edge(points: list[tuple[float, float]], style: str = "s", dashed: bool = False, arrow: bool = True) -> str:
    """直角の折れ線。style "s" = 簡易版 (太め黒)、"d" = 詳細版 (細め灰)。arrow=False で矢尻なし (分岐の幹用)。"""
    if style == "s":
        cls = "sedge" if arrow else "sedge-plain"
        if dashed:
            cls += " sedge-d"
    else:
        cls = "edge" if arrow else "edge-plain"
        if dashed:
            cls += " edge-d"

    pts = " ".join(f"{px},{py}" for px, py in points)

    if len(points) == 2:
        (x1, y1), (x2, y2) = points
        return f'<line class="{cls}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>'

    return f'<polyline class="{cls}" points="{pts}"/>'


# ---- 共有 defs / CSS / ページ ----


def defs_svg(keys: list[str] | None = None) -> str:
    """グリッド・矢尻・アイコン symbol をまとめた非表示 svg。ページ先頭に 1 回だけ置き、全図から参照する。"""
    return f"""
<svg aria-hidden="true" focusable="false" style="position:absolute;width:0;height:0;overflow:hidden">
<defs>
  <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
    <path d="M20 0 H0 V20" fill="none" stroke="#edf0f3" stroke-width="1"/>
  </pattern>
  <pattern id="grid2" width="100" height="100" patternUnits="userSpaceOnUse">
    <rect width="100" height="100" fill="url(#grid)"/>
    <path d="M100 0 H0 V100" fill="none" stroke="#e2e6ea" stroke-width="1"/>
  </pattern>
  <marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
    <path d="M0 0 L10 5 L0 10 z" fill="#545B64"/>
  </marker>
  <marker id="ar-s" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
    <path d="M0 0 L10 5 L0 10 z" fill="#232F3E"/>
  </marker>
{symbols(keys)}
</defs>
</svg>
"""


CSS = """
/* Layout: one column. Header, wide draw.io-style architecture figures in horizontal-scroll containers, footnotes. Light only. */
:root {
  --bg: #f4f5f7;
  --surface: #ffffff;
  --fg: #232f3e;
  --muted: #545b64;
  --line: #d5d9de;
  --accent: #b97f00;
  --font-body: "IBM Plex Sans JP", "Hiragino Sans", "Noto Sans JP", "Yu Gothic", sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace;
  color-scheme: light;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg); font-family: var(--font-body); font-size: 15px; line-height: 1.7; }
.page { max-width: 1480px; margin-inline: auto; padding-inline: clamp(16px, 2.5vw, 32px); padding-block: 32px 64px; display: grid; gap: 24px; }
header { display: grid; gap: 6px; }
.eyebrow { margin: 0; font-family: var(--font-mono); font-size: 12px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--accent); }
h1 { margin: 0; font-size: clamp(22px, 3vw, 30px); line-height: 1.25; font-weight: 700; text-wrap: balance; }
.lead { margin: 0; max-width: 70ch; color: var(--muted); font-size: 14px; }
figure { margin: 0; display: grid; gap: 10px; }
.scroll { overflow-x: auto; border: 1px solid var(--line); border-radius: 6px; background: #ffffff; }
.diagram { display: block; width: 100%; height: auto; min-width: 1100px; }
figcaption { font-size: 13px; color: var(--muted); max-width: 90ch; }
.notes { margin: 0; padding-left: 1.2em; display: grid; gap: 4px; max-width: 90ch; font-size: 14px; color: var(--muted); }
.notes code { font-family: var(--font-mono); font-size: 12.5px; background: #e9ecef; padding: 1px 5px; border-radius: 4px; color: var(--fg); }

/* draw.io / AWS architecture icon group styles (詳細版) */
.cloud { fill: none; stroke: #232F3E; stroke-width: 1.4; }
.region { fill: none; stroke: #00A4A6; stroke-width: 1.2; stroke-dasharray: 6 4; }
.manual { fill: #fbfbfc; stroke: #7D8998; stroke-width: 1; stroke-dasharray: 4 3; }
.stack { fill: #ffffff; stroke: #7D8998; stroke-width: 1.1; }
.card { fill: #fbfbfc; stroke: #d5d9de; stroke-width: 1; }
.t, .tb, .ts, .tm, .tm9, .te, .lbl { font-family: var(--font-body); fill: #232f3e; }
.t { font-size: 12px; }
.tb { font-size: 12px; font-weight: 700; }
.ts { font-size: 10px; fill: #545b64; }
.tm { font-family: var(--font-mono); font-size: 10.5px; }
.tm9 { font-family: var(--font-mono); font-size: 9.5px; fill: #545b64; }
.te { font-size: 9.5px; fill: #7D8998; letter-spacing: 0.04em; }
.lbl { font-size: 10px; fill: #545b64; paint-order: stroke; stroke: #ffffff; stroke-width: 4px; stroke-linejoin: round; }
.edge { fill: none; stroke: #545B64; stroke-width: 1.3; marker-end: url(#ar); }
.edge-plain { fill: none; stroke: #545B64; stroke-width: 1.3; }
.edge-d { stroke-dasharray: 4 3; }

/* simplified (icon-first) figure (簡易版) */
h2 { margin: 0 0 10px; font-size: 18px; font-weight: 700; display: flex; align-items: baseline; gap: 10px; }
h2 .num { font-family: var(--font-mono); font-size: 12px; color: var(--accent); }
section { display: grid; gap: 0; }
.sbox { fill: none; stroke: #1E88A8; stroke-width: 1.4; stroke-dasharray: 5 4; }
.stag { font-family: var(--font-body); font-size: 11px; fill: #1E88A8; letter-spacing: 0.04em; }
.sl { font-family: var(--font-body); font-size: 12.5px; font-weight: 500; fill: #232F3E; }
.sls { font-family: var(--font-body); font-size: 10.5px; fill: #545B64; }
.slbl { font-family: var(--font-body); font-size: 10.5px; fill: #545B64; paint-order: stroke; stroke: #ffffff; stroke-width: 4px; stroke-linejoin: round; }
.sedge { fill: none; stroke: #232F3E; stroke-width: 1.8; marker-end: url(#ar-s); }
.sedge-plain { fill: none; stroke: #232F3E; stroke-width: 1.8; }
.sedge-d { stroke-dasharray: 6 5; }
.dl { margin: 0; font-size: 12.5px; color: var(--muted); }
.dl a { color: #0972d3; }
"""


def figure_html(num: str, heading: str, svg: str, caption: str, img_name: str | None) -> str:
    dl = (
        f'      <p class="dl">画像: <a href="img/{img_name}.png" target="_blank">PNG</a> / <a href="img/{img_name}.svg" target="_blank">SVG</a></p>\n'
        if img_name
        else ""
    )
    return f"""  <section>
    <h2><span class="num">{e(num)}</span>{e(heading)}</h2>
    <figure>
      <div class="scroll">
{svg}
      </div>
      <figcaption>{e(caption)}</figcaption>
{dl}    </figure>
  </section>
"""


def page(
    title: str,
    eyebrow: str,
    h1: str,
    lead: str,
    figures: list[dict],
    notes: list[str],
    icon_keys: list[str] | None = None,
) -> str:
    """Artifact 用の HTML (doctype / html / head / body は付けない。Artifact 側が付ける。
    ローカルで開く場合もブラウザが補ってくれる)。
    figures: {"num", "heading", "svg", "caption", "img"} の列。notes は末尾の箇条書き (HTML 可)。"""
    sections = "".join(figure_html(f["num"], f["heading"], f["svg"], f["caption"], f.get("img")) for f in figures)
    notes_html = "\n".join(f"    <li>{n}</li>" for n in notes)
    return f"""<title>{e(title)}</title>
{FONT_LINK}
<style>{CSS}</style>

<main class="page">
{defs_svg(icon_keys)}
  <header>
    <p class="eyebrow">{e(eyebrow)}</p>
    <h1>{e(h1)}</h1>
    <p class="lead">{e(lead)}</p>
  </header>
{sections}  <ul class="notes">
{notes_html}
  </ul>
</main>
"""


def export_figures(out_dir: pathlib.Path, figures: dict[str, str], icon_keys: list[str] | None = None) -> None:
    """図ごとに standalone な HTML (PNG 化用) と SVG を書く。name.size に "w h" を書き render_png.sh が読む。"""
    out_dir.mkdir(parents=True, exist_ok=True)
    defs = defs_svg(icon_keys)
    defs_inner = defs[defs.index("<defs>"):defs.index("</defs>") + len("</defs>")]

    for name, fig in figures.items():
        vb = re.search(r'viewBox="0 0 (\d+) (\d+)"', fig)

        if vb is None:
            raise ValueError(f"{name}: viewBox=\"0 0 W H\" が見つからない")

        w, h = int(vb.group(1)), int(vb.group(2))
        fig_sized = fig.replace('class="diagram diagram-s"', 'class="diagram"').replace(
            'viewBox="0 0', f'width="{w}" height="{h}" viewBox="0 0', 1
        )
        html_doc = (
            '<!doctype html><html lang="ja"><head><meta charset="utf-8">'
            f"{FONT_LINK}<style>{CSS} body{{background:#fff}} .diagram{{min-width:0;width:{w}px;height:{h}px}}</style></head><body>"
            f"{defs}{fig_sized}</body></html>"
        )
        (out_dir / f"{name}.html").write_text(html_doc, encoding="utf-8")
        (out_dir / f"{name}.size").write_text(f"{w} {h}\n", encoding="utf-8")
        svg_doc = fig_sized.replace(
            "<svg ",
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
            1,
        ).replace(">", "><style>" + FONT_IMPORT + CSS.replace("&", "&amp;") + "</style>" + defs_inner, 1)
        (out_dir / f"{name}.svg").write_text(svg_doc, encoding="utf-8")
