#!/usr/bin/env node
// changes.json に書いた差分 (new = 足した、changed = 名前や形を変えた、removed = 消した) を、beautiful-mermaid が描いた SVG の上で塗る
// beautiful-mermaid 1.1.3 の classDiagram は style / classDef / cssClass / ::: を読まないので、描いた後に SVG を書き換える
// 何度当てても同じ結果になる (色の属性は上書きし、このスクリプトが足した <tspan> と <marker> は外してから付け直す)
// 使い方: node mark-changes.mjs src/changes.json 1-overview.svg 2-customers.svg ... (scripts/render.sh が呼ぶ)
import { readFileSync, writeFileSync } from "node:fs";

// removed は破線の枠と線、文字は取り消し線 (消したものは part に残して描き、ここで消した見た目にする)
const PALETTE = {
	new: { fill: "#dcfce7", header: "#bbf7d0", stroke: "#16a34a", text: "#15803d", weight: "700", lineWidth: "2" },
	changed: { fill: "#ede9fe", header: "#ddd6fe", stroke: "#7c3aed", text: "#6d28d9", weight: "700", lineWidth: "2" },
	removed: { fill: "#fee2e2", header: "#fecaca", stroke: "#dc2626", text: "#b91c1c", weight: "400", lineWidth: "1.5", dash: "5 3", strike: true },
};
const KINDS = ["new", "changed", "removed"];
const BOX_WIDTH = "1.5";

const textAttrs = (kind) => {
	return {
		fill: PALETTE[kind].text,
		"font-weight": PALETTE[kind].weight,
		...(PALETTE[kind].strike ? { "text-decoration": "line-through" } : {}),
	};
};

const dashAttrs = (kind) => {
	return PALETTE[kind].dash === undefined ? {} : { "stroke-dasharray": PALETTE[kind].dash };
};

const [changesPath, ...svgPaths] = process.argv.slice(2);

if (changesPath === undefined || svgPaths.length === 0) {
	console.error("使い方: node mark-changes.mjs src/changes.json <svg>...");
	process.exit(1);
}

const changes = JSON.parse(readFileSync(changesPath, "utf8"));

const unescapeXml = (s) => {
	return s.replaceAll("&lt;", "<").replaceAll("&gt;", ">").replaceAll("&quot;", '"').replaceAll("&#39;", "'").replaceAll("&amp;", "&");
};

const getAttr = (tag, name) => {
	const m = tag.match(new RegExp(`\\s${name}="([^"]*)"`));
	return m === null ? undefined : unescapeXml(m[1]);
};

// 開きタグの属性を上書きする (無ければ足す)
const setAttr = (tag, name, value) => {
	const re = new RegExp(`(\\s${name}=)"[^"]*"`);
	return re.test(tag) ? tag.replace(re, `$1"${value}"`) : tag.replace(/\s*(\/?>)$/, ` ${name}="${value}"$1`);
};

const setAttrs = (tag, attrs) => {
	return Object.entries(attrs).reduce((t, [k, v]) => setAttr(t, k, v), tag);
};

// 行の先頭の開きタグだけを書き換える
const editOpenTag = (line, attrs) => {
	return line.replace(/<[^>]*>/, (tag) => setAttrs(tag, attrs));
};

const visibleText = (line) => {
	return unescapeXml(line.replace(/<[^>]*>/g, "")).trim();
};

// part に書いた属性の行が描かれる形。空白を含む行は「型 名前」と読まれ「名前: 型」と描かれる
const renderedMember = (source) => {
	const parts = source.trim().split(/\s+/);
	return parts.length >= 2 ? `${parts.slice(1).join(" ")}: ${parts[0]}` : source.trim();
};

// changes.json の項目のうち、どの SVG にも当たらなかったものを最後に知らせる
const hits = new Set();

const record = (kind, key) => {
	if (kind !== undefined) {
		hits.add(key);
	}

	return kind;
};

const kindOfEntity = (id) => {
	const kind = KINDS.find((k) => (changes[k]?.entities ?? []).includes(id));
	return record(kind, `entity:${id}`);
};

const kindOfAttribute = (id, text) => {
	const kind = KINDS.find((k) => (changes[k]?.attributes?.[id] ?? []).map(renderedMember).includes(text));
	return record(kind, `attribute:${id}:${text}`);
};

// 消した実体の中の「分割先」「移した先」の行は、取り消し線を引かずに赤の斜体にする
const isNote = (id, text) => {
	const found = (changes.removed?.notes?.[id] ?? []).map(renderedMember).includes(text);
	return record(found ? "removed" : undefined, `note:${id}:${text}`) !== undefined;
};

const kindOfRelation = (from, to) => {
	const key = `${from} -> ${to}`;
	const kind = KINDS.find((k) => (changes[k]?.relations ?? []).includes(key));
	return record(kind, `relation:${key}`);
};

const markEntityLine = (line, kind) => {
	return line.startsWith("  <line") ? editOpenTag(line, { stroke: PALETTE[kind].stroke }) : line;
};

const markClassNode = (group) => {
	const lines = group.split("\n");
	const id = getAttr(lines[0], "data-id") ?? "";
	const kind = kindOfEntity(id);
	const rectIndexes = lines.flatMap((line, i) => (line.startsWith("  <rect") ? [i] : []));

	const markRect = (line, i) => {
		if (kind === undefined) {
			return line;
		}

		const fill = i === rectIndexes[0] ? PALETTE[kind].fill : PALETTE[kind].header;
		return editOpenTag(line, { fill, stroke: PALETTE[kind].stroke, "stroke-width": BOX_WIDTH, ...dashAttrs(kind) });
	};

	const colorTspans = (line, kind) => {
		return line.replace(/(<tspan[^>]*\sfill=)"[^"]*"/g, `$1"${PALETTE[kind].text}"`);
	};

	// 消した実体の属性は、changes.json に書かなくても全部消した見た目にする
	const markMember = (line) => {
		const text = visibleText(line);

		if (kind === "removed" && isNote(id, text)) {
			return editOpenTag(colorTspans(line, "removed"), { "font-style": "italic" });
		}

		const attrKind = kindOfAttribute(id, text) ?? (kind === "removed" ? "removed" : undefined);

		if (attrKind === undefined) {
			return line;
		}

		// 取り消し線の色は text 要素の fill で決まるので、消した行だけは text 側にも fill を付ける
		const { fill: _, ...rest } = textAttrs(attrKind);
		return editOpenTag(colorTspans(line, attrKind), PALETTE[attrKind].strike ? textAttrs(attrKind) : rest);
	};

	// 消した実体は表名の注記と実体名も取り消し線にする
	const markHeaderText = (line) => {
		return kind === "removed" ? editOpenTag(line, { fill: PALETTE.removed.text, "text-decoration": "line-through" }) : line;
	};

	const markLine = (line, i) => {
		if (rectIndexes.includes(i)) {
			return markRect(line, i);
		}

		if (line.includes('class="mono"')) {
			return markMember(line);
		}

		if (line.startsWith("  <text")) {
			return markHeaderText(line);
		}

		return kind === undefined ? line : markEntityLine(line, kind);
	};

	return lines.map(markLine).join("\n");
};

// flowchart (1-overview) の箱の中の「実体 / 実体 / ...」の行は、実体名ごとに色を付ける
const wrapToken = (token) => {
	const kind = kindOfEntity(unescapeXml(token));
	const attrs = Object.entries(textAttrs(kind ?? "new"))
		.map(([k, v]) => `${k}="${v}"`)
		.join(" ");
	return kind === undefined ? token : `<tspan data-change="${kind}" ${attrs}>${token}</tspan>`;
};

const markFlowNode = (group) => {
	const plain = group.replace(/<tspan data-change="[^"]*"[^>]*>([^<]*)<\/tspan>/g, "$1");
	return plain.replace(/(<tspan x="[^"]*" dy="[^"]*">)([^<]*)(<\/tspan>)/g, (_, open, content, close) => {
		return `${open}${content.split(" / ").map(wrapToken).join(" / ")}${close}`;
	});
};

const markFlowEdgeLabel = (group) => {
	const lines = group.split("\n");
	const kind = kindOfRelation(getAttr(lines[0], "data-from"), getAttr(lines[0], "data-to"));

	if (kind === undefined) {
		return group;
	}

	const markLine = (line) => {
		if (line.startsWith("  <rect")) {
			return editOpenTag(line, { stroke: PALETTE[kind].stroke, "stroke-width": BOX_WIDTH, ...dashAttrs(kind) });
		}

		if (line.startsWith("  <text")) {
			return editOpenTag(line, textAttrs(kind));
		}

		return line;
	};

	return lines.map(markLine).join("\n");
};

const markerIdOf = (base, kind) => {
	return `${base}-${kind}`;
};

const markLineElement = (line, kind) => {
	const marker = (value) => {
		return value === undefined ? undefined : value.replace(/url\(#([\w-]+?)(?:-new|-changed|-removed)?\)/, (_, base) => `url(#${markerIdOf(base, kind)})`);
	};
	const start = marker(getAttr(line, "marker-start"));
	const end = marker(getAttr(line, "marker-end"));
	return editOpenTag(line, {
		stroke: PALETTE[kind].stroke,
		"stroke-width": PALETTE[kind].lineWidth,
		...dashAttrs(kind),
		...(start === undefined ? {} : { "marker-start": start }),
		...(end === undefined ? {} : { "marker-end": end }),
	});
};

const isClassRelationship = (line) => {
	return line.startsWith("<polyline") && line.includes('class="class-relationship"');
};

const isFlowEdge = (line) => {
	return line.startsWith("<polyline") && line.includes('class="edge"');
};

// classDiagram の関係のラベルと多重度は、最後の実体の後に関係の順で 1 つずつ並ぶ (ラベル、元の多重度、先の多重度。無いものは飛ばす)
// 返すのは 行番号 -> { kind, isLabel }。取り消し線はラベルにだけ引く
const relationLabelKinds = (lines) => {
	const lastGroupEnd = lines.findLastIndex((line) => line === "</g>");
	const textIndexes = lines.flatMap((line, i) => (i > lastGroupEnd && line.startsWith("<text") ? [i] : []));
	const relations = lines.filter(isClassRelationship);
	const counts = relations.map((line) => ["data-label", "data-from-cardinality", "data-to-cardinality"].filter((name) => getAttr(line, name) !== undefined).length);
	const starts = counts.map((_, i) => counts.slice(0, i).reduce((a, b) => a + b, 0));
	const kinds = relations.map((line) => kindOfRelation(getAttr(line, "data-from"), getAttr(line, "data-to")));
	return Object.fromEntries(
		relations.flatMap((line, r) => {
			const hasLabel = getAttr(line, "data-label") !== undefined;
			return textIndexes.slice(starts[r], starts[r] + counts[r]).map((index, j) => [index, { kind: kinds[r], isLabel: hasLabel && j === 0 }]);
		}),
	);
};

const MARKERS = {
	"cls-arrow": (color) => {
		return `<polyline points="0 0, 8 3, 0 6" fill="none" stroke="${color}" stroke-width="1.5" />`;
	},
	arrowhead: (color) => {
		return `<polygon points="0 0, 8 2.5, 0 5" fill="${color}" stroke="${color}" stroke-width="0.75" stroke-linejoin="round" />`;
	},
};

// 色の付いた矢じり。線を太くしても矢じりが大きくならないよう userSpaceOnUse で描く
const markerDefs = (svg) => {
	const used = [...svg.matchAll(/url\(#([\w-]+)-(new|changed|removed)\)/g)].map((m) => `${m[1]}|${m[2]}`);
	const unique = [...new Set(used)].toSorted();
	return unique.map((key) => {
		const [base, kind] = key.split("|");
		const original = svg.match(new RegExp(`<marker id="${base}"[^>]*>`));
		const open = original === null ? `<marker id="${base}">` : original[0];
		const tag = setAttrs(open, { id: markerIdOf(base, kind), markerUnits: "userSpaceOnUse", "data-change": kind });
		return `  ${tag}\n    ${MARKERS[base](PALETTE[kind].stroke)}\n  </marker>`;
	});
};

const markSvg = (svg) => {
	const withoutOldMarkers = svg.replace(/\n {2}<marker [^>]*data-change="[^"]*"[^>]*>[\s\S]*?<\/marker>/g, "");
	const withGroups = withoutOldMarkers
		.replace(/<g class="class-node"[^>]*>[\s\S]*?<\/g>/g, markClassNode)
		.replace(/<g class="node"[^>]*>[\s\S]*?<\/g>/g, markFlowNode)
		.replace(/<g class="edge-label"[^>]*>[\s\S]*?<\/g>/g, markFlowEdgeLabel);
	const lines = withGroups.split("\n");
	const labelKinds = relationLabelKinds(lines);

	const markLine = (line, i) => {
		if (isClassRelationship(line) || isFlowEdge(line)) {
			const kind = kindOfRelation(getAttr(line, "data-from"), getAttr(line, "data-to"));
			return kind === undefined ? line : markLineElement(line, kind);
		}

		const label = labelKinds[i];

		if (label === undefined || label.kind === undefined) {
			return line;
		}

		const { "text-decoration": strike, ...rest } = textAttrs(label.kind);
		return editOpenTag(line, label.isLabel || strike === undefined ? textAttrs(label.kind) : rest);
	};

	const marked = lines.map(markLine).join("\n");
	const defs = markerDefs(marked);
	return defs.length === 0 ? marked : marked.replace("</defs>", `${defs.join("\n")}\n</defs>`);
};

svgPaths.map((path) => {
	writeFileSync(path, markSvg(readFileSync(path, "utf8")));
	return path;
});

const expected = KINDS.flatMap((k) => [
	...(changes[k]?.entities ?? []).map((id) => `entity:${id}`),
	...Object.entries(changes[k]?.attributes ?? {}).flatMap(([id, list]) => list.map((source) => `attribute:${id}:${renderedMember(source)}`)),
	...(changes[k]?.relations ?? []).map((key) => `relation:${key}`),
	...Object.entries(changes[k]?.notes ?? {}).flatMap(([id, list]) => list.map((source) => `note:${id}:${renderedMember(source)}`)),
]);
const missed = expected.filter((key) => !hits.has(key));

if (missed.length > 0) {
	console.error(`mark-changes: changes.json のうち、どの SVG にも当たらなかったもの:\n  ${missed.join("\n  ")}`);
	process.exit(1);
}

console.log(`mark-changes: ${svgPaths.length} 枚に差分の色を付けた (${expected.length} 項目)`);
