#!/usr/bin/env node
// Claude Code の statusLine スクリプト (2 行構成)。
// 1 行目: プロファイル / モデル / 場所 (worktree 対応、Explorer リンク付き) / ブランチ / MR
// 2 行目: コンテキスト使用量 / レート制限 / 異常系バッジ
// I/O (stdin, fs, env, 時刻) は main に閉じ込め、render 以下は純粋関数にしてテストする。
import { existsSync, readFileSync, realpathSync, statSync } from "fs";
import { homedir } from "os";
import { basename, dirname, join, relative, resolve, sep } from "path";
import { text } from "stream/consumers";
import { fileURLToPath } from "url";

const ANSI = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
};
const OSC8_START = "\x1b]8;;";
const OSC8_END = "\x1b\\";

const DANGER_PERCENT = 90;
const WARN_PERCENT = 70;
const BAR_WIDTH = 10;
const WIDE_COLUMNS = 100;
const BRANCH_MAX_WIDE = 40;
const BRANCH_MAX_NARROW = 24;
// 既定プロファイルは表示しない (出ていないこと自体を既定のシグナルにする)
const DEFAULT_PROFILE = "claude";
const SEPARATOR = ` ${ANSI.dim}｜${ANSI.reset} `;
// Nerd Font のアイコン
const DIR_ICON = "\u{F4D3}"; // nf-oct-file_directory_fill
const BRANCH_ICON = "\u{E0A0}"; // nf-pl-branch

/**
 * @typedef {object} Worktree
 * @property {string} mainRepo 本体リポジトリのルート
 * @property {string} name .git/worktrees/<name> の name
 */

/**
 * @typedef {object} GitInfo
 * @property {string} root 作業ツリーのルート (worktree ならその worktree のルート)
 * @property {string} [branch] ブランチ名。detached HEAD なら短縮 SHA
 * @property {Worktree} [worktree] linked worktree のときのみ
 */

/**
 * @typedef {object} Context
 * @property {string} home
 * @property {string} ghqRoot ghq のルート。この配下は <host>/<owner>/<name> 固定なので短縮対象
 * @property {number} [columns]
 * @property {string} [wslDistro]
 * @property {string} timeZone
 * @property {GitInfo} [git]
 */

/** @typedef {"wide" | "narrow"} Tier */

// ---------------------------------------------------------------------------
// 共通ユーティリティ
// ---------------------------------------------------------------------------

const isDefined = (value) => {
  return value !== undefined;
};

const isPercent = (value) => {
  return typeof value === "number" && Number.isFinite(value);
};

const thresholdColor = (percent) => {
  if (percent >= DANGER_PERCENT) {
    return ANSI.red;
  }

  if (percent >= WARN_PERCENT) {
    return ANSI.yellow;
  }

  return ANSI.green;
};

const tildify = (path, home) => {
  if (path.startsWith(home)) {
    return `~${path.slice(home.length)}`;
  }

  return path;
};

const truncate = (value, max) => {
  const chars = [...value];

  if (chars.length <= max) {
    return value;
  }

  return `${chars.slice(0, max - 1).join("")}…`;
};

const hyperlink = (label, url) => {
  return `${OSC8_START}${url}${OSC8_END}${label}${OSC8_START}${OSC8_END}`;
};

const formatClock = (date, timeZone) => {
  return new Intl.DateTimeFormat("ja-JP", { hour: "2-digit", minute: "2-digit", hour12: false, timeZone }).format(date);
};

const formatDayClock = (date, timeZone) => {
  return new Intl.DateTimeFormat("ja-JP", {
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    timeZone,
  }).format(date);
};

// ---------------------------------------------------------------------------
// 1 行目のセグメント
// ---------------------------------------------------------------------------

const getProfile = (transcriptPath) => {
  if (typeof transcriptPath !== "string" || transcriptPath === "") {
    return undefined;
  }

  // transcript_path: <CONFIG_DIR>/projects/<encoded-cwd>/<session>.jsonl の構造で、3 階層上が CONFIG_DIR
  const configDir = dirname(dirname(dirname(transcriptPath)));
  const name = basename(configDir).replace(/^\./, "");

  if (name === "" || name === DEFAULT_PROFILE) {
    return undefined;
  }

  // ".claude-work" -> "work"
  return name.replace(new RegExp(`^${DEFAULT_PROFILE}-`), "");
};

const renderProfile = (data) => {
  const profile = getProfile(data.transcript_path);

  if (profile === undefined) {
    return undefined;
  }

  return `${ANSI.bold}${ANSI.magenta}[${profile}]${ANSI.reset}`;
};

const shortenModelName = (displayName) => {
  if (typeof displayName !== "string" || displayName === "") {
    return "?";
  }

  // "Opus 5 (1M context)" -> "Opus 5·1M"
  const match = /^(.*?)\s*\((\d+[KM]) context\)$/i.exec(displayName);

  if (match === null) {
    return displayName;
  }

  return `${match[1]}·${match[2]}`;
};

const renderModel = (data) => {
  const name = `[${shortenModelName(data.model?.display_name)}]`;
  const effort = data.effort?.level;

  if (effort === undefined) {
    return name;
  }

  return `${name}[${effort}]`;
};

const shortWorktreeName = (name, repoName) => {
  // 兄弟ディレクトリ型 (<repo>-<slug>) は接頭辞を剥がして slug だけにする
  if (name.startsWith(`${repoName}-`)) {
    return name.slice(repoName.length + 1);
  }

  return name;
};

const subPath = (dir, root) => {
  const rel = relative(root, dir);

  if (rel === "" || rel.startsWith("..")) {
    return "";
  }

  return `/${rel}`;
};

// ghq 配下 (<root>/<host>/<owner>/<name>) は root と host を落として owner/name にする
const stripGhq = (path, ghqRoot) => {
  if (!path.startsWith(`${ghqRoot}/`)) {
    return undefined;
  }

  const segments = path.slice(ghqRoot.length + 1).split("/");

  if (segments.length < 3) {
    return undefined;
  }

  return segments.slice(1).join("/");
};

const shortenPath = (path, ctx) => {
  return stripGhq(path, ctx.ghqRoot) ?? tildify(path, ctx.home);
};

const formatLocation = (dir, ctx, tier) => {
  const git = ctx.git;
  const worktree = git?.worktree;
  const top = worktree?.mainRepo ?? git?.root ?? dir;
  const head = tier === "wide" ? shortenPath(top, ctx) : basename(top);
  const worktreePart =
    worktree === undefined
      ? ""
      : ` ⌂ ${ANSI.cyan}${shortWorktreeName(worktree.name, basename(worktree.mainRepo))}${ANSI.reset}`;
  const sub = git === undefined ? "" : subPath(dir, git.root);

  return `${head}${worktreePart}${sub}`;
};

const directoryUrl = (dir, wslDistro) => {
  const path = encodeURI(dir);

  if (wslDistro === undefined) {
    return `file://${path}`;
  }

  // Windows Terminal 1.17+ は file://wsl.localhost/<distro>/... を ShellExecute で開ける
  return `file://wsl.localhost/${wslDistro}${path}`;
};

const renderLocation = (data, ctx, tier) => {
  const dir = data.workspace?.current_dir ?? data.cwd;

  if (typeof dir !== "string" || dir === "") {
    return undefined;
  }

  return hyperlink(`${DIR_ICON} ${formatLocation(dir, ctx, tier)}`, directoryUrl(dir, ctx.wslDistro));
};

const renderBranch = (_data, ctx, tier) => {
  const branch = ctx.git?.branch;

  if (branch === undefined) {
    return undefined;
  }

  const max = tier === "wide" ? BRANCH_MAX_WIDE : BRANCH_MAX_NARROW;

  return `${BRANCH_ICON} ${truncate(branch, max)}`;
};

const PR_COLORS = {
  approved: ANSI.green,
  changes_requested: ANSI.red,
  draft: ANSI.dim,
};

const prColor = (reviewState) => {
  if (typeof reviewState !== "string") {
    return ANSI.yellow;
  }

  return PR_COLORS[reviewState] ?? ANSI.yellow;
};

const renderPr = (data) => {
  const pr = data.pr;

  if (typeof pr?.number !== "number") {
    return undefined;
  }

  const prefix = pr.kind === "mr" ? "!" : "#";
  const label = `${prColor(pr.review_state)}${prefix}${pr.number}${ANSI.reset}`;

  if (typeof pr.url !== "string") {
    return label;
  }

  return hyperlink(label, pr.url);
};

// ---------------------------------------------------------------------------
// 2 行目のセグメント
// ---------------------------------------------------------------------------

const renderBar = (percent) => {
  const filled = Math.min(BAR_WIDTH, Math.round((percent / 100) * BAR_WIDTH));

  return `${"█".repeat(filled)}${"░".repeat(BAR_WIDTH - filled)}`;
};

const formatTokens = (tokens) => {
  if (tokens >= 1_000_000) {
    return `${(tokens / 1_000_000).toFixed(1)}M`;
  }

  return `${Math.round(tokens / 1000)}k`;
};

const renderTokens = (tokens, exceeds200k) => {
  if (typeof tokens !== "number" || tokens <= 0) {
    return "";
  }

  // 200k 超えは 1M 運用だと定常状態になるのでバッジにせず色だけ変える
  const color = exceeds200k ? ANSI.yellow : ANSI.dim;

  return ` ${color}${formatTokens(tokens)}${ANSI.reset}`;
};

const renderContext = (data, _ctx, tier) => {
  const percent = data.context_window?.used_percentage;

  if (!isPercent(percent)) {
    return undefined;
  }

  const rounded = Math.round(percent);
  const color = thresholdColor(rounded);
  const bar = tier === "wide" ? `${color}${renderBar(rounded)}${ANSI.reset} ` : "";
  const tokens = renderTokens(data.context_window.total_input_tokens, data.exceeds_200k_tokens === true);

  return `⛁ ${bar}${color}${rounded}%${ANSI.reset}${tokens}`;
};

const renderReset = (resetsAt, format, timeZone) => {
  if (typeof resetsAt !== "number") {
    return "";
  }

  return ` ${ANSI.dim}→${format(new Date(resetsAt * 1000), timeZone)}${ANSI.reset}`;
};

// rate_limits.<key> を 1 セグメントにする。枠が増えたら RATE_WINDOWS に行を足す
const renderRateWindow = ({ key, label, formatReset }) => {
  return (data, ctx, tier) => {
    const window = data.rate_limits?.[key];
    const percent = window?.used_percentage;

    if (!isPercent(percent)) {
      return undefined;
    }

    const rounded = Math.round(percent);
    // リセット時刻は溜まってきたときだけ出す (ペース配分の判断材料)。狭い幅では省く
    const showReset = rounded >= WARN_PERCENT && tier === "wide";
    const reset = showReset ? renderReset(window.resets_at, formatReset, ctx.timeZone) : "";

    return `${label} ${thresholdColor(rounded)}${rounded}%${ANSI.reset}${reset}`;
  };
};

const RATE_WINDOWS = [
  { key: "five_hour", label: "5h", formatReset: formatClock },

  { key: "seven_day", label: "7d", formatReset: formatDayClock },

  { key: "spend_limit", label: "spend", formatReset: formatDayClock },
];

const renderCache = (data) => {
  const cache = data.prompt_cache;

  if (cache?.caching_observed !== true || cache.warm !== false) {
    return undefined;
  }

  return `${ANSI.yellow}❄ cache${ANSI.reset}`;
};

const renderFast = (data) => {
  if (data.fast_mode !== true) {
    return undefined;
  }

  return `${ANSI.yellow}⚡fast${ANSI.reset}`;
};

const renderThinking = (data) => {
  if (data.thinking?.enabled !== false) {
    return undefined;
  }

  return `${ANSI.red}no-think${ANSI.reset}`;
};

const renderAgent = (data) => {
  const name = data.agent?.name;

  if (typeof name !== "string" || name === "") {
    return undefined;
  }

  return `agent:${name}`;
};

// ---------------------------------------------------------------------------
// 行の組み立て
// ---------------------------------------------------------------------------

// 各行はグループの配列。グループ内はスペース、グループ間は SEPARATOR で結合する
const LINE1_GROUPS = [
  [renderProfile, renderModel],

  [renderLocation, renderBranch, renderPr],
];

const LINE2_GROUPS = [
  [renderContext],

  ...RATE_WINDOWS.map((window) => [renderRateWindow(window)]),

  [renderCache, renderFast, renderThinking, renderAgent],
];

const renderGroup = (segments, data, ctx, tier) => {
  const parts = segments.map((segment) => segment(data, ctx, tier)).filter(isDefined);

  if (parts.length === 0) {
    return undefined;
  }

  return parts.join(" ");
};

const renderLine = (groups, data, ctx, tier) => {
  const rendered = groups.map((segments) => renderGroup(segments, data, ctx, tier)).filter(isDefined);

  if (rendered.length === 0) {
    return undefined;
  }

  return rendered.join(SEPARATOR);
};

const resolveTier = (columns) => {
  if (columns !== undefined && columns < WIDE_COLUMNS) {
    return "narrow";
  }

  return "wide";
};

/**
 * statusLine の出力文字列を組み立てる純粋関数。
 * @param {object} data Claude Code が stdin で渡す JSON
 * @param {Context} ctx 環境依存の値
 * @returns {string} 1 行または 2 行 (改行区切り)
 */
export const render = (data, ctx) => {
  const tier = resolveTier(ctx.columns);

  return [renderLine(LINE1_GROUPS, data, ctx, tier), renderLine(LINE2_GROUPS, data, ctx, tier)]
    .filter(isDefined)
    .join("\n");
};

// ---------------------------------------------------------------------------
// git 情報 (git プロセスは起動せず .git を直読みする)
// ---------------------------------------------------------------------------

// "/a/b/c" -> ["/a/b/c", "/a/b", "/a", "/"]
const ancestors = (dir) => {
  const parts = dir.split(sep).filter((part) => part !== "");

  return [...parts.map((_, i) => `${sep}${parts.slice(0, parts.length - i).join(sep)}`), sep];
};

const hasDotGit = (dir) => {
  return existsSync(join(dir, ".git"));
};

const resolveGitDir = (root) => {
  const dotGit = join(root, ".git");

  if (statSync(dotGit).isDirectory()) {
    return dotGit;
  }

  // linked worktree / submodule では .git がファイルで "gitdir: <path>" を持つ
  const match = /^gitdir:\s*(.+)$/m.exec(readFileSync(dotGit, "utf8"));

  if (match === null) {
    return undefined;
  }

  return resolve(root, match[1].trim());
};

const readHead = (gitDir) => {
  const headPath = join(gitDir, "HEAD");

  if (!existsSync(headPath)) {
    return undefined;
  }

  const head = readFileSync(headPath, "utf8").trim();
  const ref = /^ref: refs\/heads\/(.+)$/.exec(head);

  if (ref !== null) {
    return ref[1];
  }

  return head.slice(0, 7);
};

const detectWorktree = (gitDir) => {
  // linked worktree の gitdir は <main>/.git/worktrees/<name>
  if (basename(dirname(gitDir)) !== "worktrees") {
    return undefined;
  }

  return { mainRepo: dirname(dirname(dirname(gitDir))), name: basename(gitDir) };
};

/**
 * cwd から上へ辿って .git を探し、ブランチと worktree 情報を返す。
 * @param {string | undefined} dir
 * @returns {GitInfo | undefined}
 */
export const readGitInfo = (dir) => {
  if (typeof dir !== "string" || dir === "") {
    return undefined;
  }

  const root = ancestors(dir).find(hasDotGit);

  if (root === undefined) {
    return undefined;
  }

  const gitDir = resolveGitDir(root);

  if (gitDir === undefined) {
    return undefined;
  }

  return { root, branch: readHead(gitDir), worktree: detectWorktree(gitDir) };
};

// ---------------------------------------------------------------------------
// エントリポイント
// ---------------------------------------------------------------------------

const safeParse = (input) => {
  try {
    const parsed = JSON.parse(input);

    return typeof parsed === "object" && parsed !== null ? parsed : {};
  } catch {
    return {};
  }
};

const parseColumns = (raw) => {
  const columns = Number(raw);

  return Number.isInteger(columns) && columns > 0 ? columns : undefined;
};

const readGitInfoSafe = (dir) => {
  try {
    return readGitInfo(dir);
  } catch {
    return undefined;
  }
};

const main = async () => {
  const data = safeParse(await text(process.stdin));
  const ctx = {
    home: homedir(),
    ghqRoot: (process.env.GHQ_ROOT ?? join(homedir(), "ghq")).replace(/\/+$/, ""),
    columns: parseColumns(process.env.COLUMNS),
    wslDistro: process.env.WSL_DISTRO_NAME,
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    git: readGitInfoSafe(data.workspace?.current_dir ?? data.cwd),
  };

  process.stdout.write(render(data, ctx));
};

// symlink 経由 (~/.claude/statusline-v2.mjs) で起動されるので realpath で比較する
const isEntryPoint = () => {
  const argv1 = process.argv[1];

  if (argv1 === undefined) {
    return false;
  }

  try {
    return realpathSync(argv1) === fileURLToPath(import.meta.url);
  } catch {
    return false;
  }
};

if (isEntryPoint()) {
  main().catch(() => {
    process.exit(0);
  });
}
