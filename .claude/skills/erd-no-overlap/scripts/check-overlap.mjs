// ラベルの箱と、自分の線との距離 / 他の線・他のラベル・表の箱との重なりを数える
import { readFileSync } from "node:fs";
const svg = readFileSync(process.argv[2], "utf8");
const attr = (t, n) => { const m = t.match(new RegExp(`\\s${n}="([^"]*)"`)); return m ? m[1] : undefined; };
const polys = [...svg.matchAll(/<polyline\b[^>]*\/>/g)].map((m) => ({ label: attr(m[0], "data-label"), e1: attr(m[0], "data-entity1"), e2: attr(m[0], "data-entity2"), pts: attr(m[0], "points").split(" ").map((p) => p.split(",").map(Number)) }));
const ents = [...svg.matchAll(/<g class="entity"[^>]*>\s*<rect\b[^>]*\/>/g)].map((m) => { const r = m[0].match(/<rect\b[^>]*\/>/)[0]; return { id: attr(m[0], "data-id"), x: +attr(r, "x"), y: +attr(r, "y"), w: +attr(r, "width"), h: +attr(r, "height") }; });
const tail = svg.slice(svg.lastIndexOf("</g>"));
const labels = [...tail.matchAll(/<rect\b([^>]*rx="2"[^>]*)\/>\s*<text\b[^>]*>([\s\S]*?)<\/text>/g)].map((m) => ({ x: +attr(m[0], "x"), y: +attr(m[0], "y"), w: +attr(m[0], "width"), h: +attr(m[0], "height"), text: m[2].replace(/<[^>]+>/g, "") }));
const withLabel = polys.filter((p) => p.label);
const segHitsRect = (a, b, r, pad = 0) => { const [x1, y1] = a, [x2, y2] = b; const minx = Math.min(x1, x2), maxx = Math.max(x1, x2), miny = Math.min(y1, y2), maxy = Math.max(y1, y2); return maxx >= r.x - pad && minx <= r.x + r.w + pad && maxy >= r.y - pad && miny <= r.y + r.h + pad; };
const distSeg = ([px, py], [x1, y1], [x2, y2]) => { const dx = x2 - x1, dy = y2 - y1; const t = Math.max(0, Math.min(1, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy || 1))); return Math.hypot(px - x1 - t * dx, py - y1 - t * dy); };
let problems = 0;
labels.forEach((l, i) => {
  const own = withLabel[i];
  const c = [l.x + l.w / 2, l.y + l.h / 2];
  const d = Math.min(...own.pts.slice(1).map((p, j) => distSeg(c, own.pts[j], p)));
  const others = withLabel.filter((p, j) => j !== i && p.pts.slice(1).some((q, k) => segHitsRect(p.pts[k], q, l)));
  const lab = labels.filter((m, j) => j !== i && m.x < l.x + l.w && l.x < m.x + m.w && m.y < l.y + l.h && l.y < m.y + m.h);
  const box = ents.filter((e) => e.x < l.x + l.w && l.x < e.x + e.w && e.y < l.y + l.h && l.y < e.y + e.h);
  const bad = others.length + lab.length + box.length > 0;
  if (bad) problems++;
  if (bad || process.argv[3] === "-v") console.log(`${bad ? "NG" : "ok"} ${own.e1}->${own.e2} "${l.text}" 自分の線まで ${d.toFixed(0)}px 他の線 ${others.map((o) => `${o.e1}->${o.e2}`).join(",")} ラベル ${lab.map((m) => m.text).join(",")} 箱 ${box.map((b) => b.id).join(",")}`);
});
console.log(`${process.argv[2].split("/").pop()}: ラベル ${labels.length} / 線 ${withLabel.length} / 重なり ${problems}`);
