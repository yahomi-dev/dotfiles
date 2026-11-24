// Claude Code の PostToolUse hook
// インデントされた JSDoc (/**) の直前の行がメンバー行 (; か , で終わり、同じインデント) なら空行を 1 行入れる
// Edit / Write では tool_input.file_path を、Bash では cwd と .claude/worktrees 配下の git 変更ファイルを対象にする
import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const TS_FILE = /\.(ts|tsx|mts|cts)$/;
const SKIP_PATH = /(^|\/)(node_modules|\.next|dist)\//;

const fixText = (text) => {
  const lines = text.split("\n");
  const out = [];
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const doc = /^(\s+)\/\*\*/.exec(line);
    if (doc && i > 0) {
      const prev = lines[i - 1];
      const prevTrim = prev.trimEnd();
      const prevIndent = /^\s*/.exec(prev)[0];
      const endsMember = /[;,]$/.test(prevTrim);
      const prevIsComment = /^\s*(\/\/|\*|\/\*)/.test(prev);
      if (prevTrim !== "" && endsMember && !prevIsComment && prevIndent === doc[1]) {
        out.push("");
      }
    }
    out.push(line);
  }
  return out.join("\n");
};

const gitChanged = (dir) => {
  try {
    const out = execFileSync(
      "git",
      ["-C", dir, "status", "--porcelain", "-uall", "--no-renames"],
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    );
    return out
      .split("\n")
      .filter((l) => l.length > 3)
      .map((l) => l.slice(3))
      .filter((p) => TS_FILE.test(p) && !SKIP_PATH.test(p))
      .map((p) => resolve(dir, p));
  } catch {
    return [];
  }
};

const changedTsFiles = (cwd) => {
  const worktrees = join(cwd, ".claude", "worktrees");
  const dirs = existsSync(worktrees)
    ? [cwd, ...readdirSync(worktrees).map((d) => join(worktrees, d))]
    : [cwd];
  return dirs.flatMap(gitChanged);
};

const targetFiles = (hook) => {
  const filePath = hook?.tool_input?.file_path;
  if (typeof filePath === "string") {
    return [filePath];
  }
  if (hook?.tool_name === "Bash") {
    return changedTsFiles(hook.cwd ?? process.cwd());
  }
  return [];
};

const readHookInput = () => {
  try {
    return JSON.parse(readFileSync(0, "utf8"));
  } catch {
    return {};
  }
};

const changed = [];
for (const file of new Set(targetFiles(readHookInput()))) {
  if (!TS_FILE.test(file) || SKIP_PATH.test(file) || !existsSync(file)) {
    continue;
  }
  const before = readFileSync(file, "utf8");
  const after = fixText(before);
  if (after !== before) {
    writeFileSync(file, after);
    changed.push(file);
  }
}
if (changed.length > 0) {
  console.log(`jsdoc-member-spacing: ${changed.join(", ")}`);
}
