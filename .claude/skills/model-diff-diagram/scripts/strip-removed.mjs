// 最終版の全体図 (9-all-final) 用。標準入力の mmd から、changes.json の removed.attributes にある属性の行を取り除く
// (消した実体と消した関係は _removed-*.part に分けてあるので、ここでは既存の実体の中に残した消した行だけを落とす)
import { readFileSync } from "node:fs";
const changes = JSON.parse(readFileSync(process.argv[2], "utf8"));
const removed = new Set(Object.values(changes.removed?.attributes ?? {}).flat());
const lines = readFileSync(0, "utf8").split("\n");
process.stdout.write(lines.filter((l) => !removed.has(l.trim())).join("\n"));
