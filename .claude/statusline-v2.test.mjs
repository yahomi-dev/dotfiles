// 実行: node --test ~/dotfiles/.claude/statusline-v2.test.mjs
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, describe, test } from "node:test";
import { readGitInfo, render } from "./statusline-v2.mjs";

const HOME = "/home/u";
const DIR = "\u{F4D3}";
const WIDE_CTX = { home: HOME, ghqRoot: `${HOME}/ghq`, columns: 160, wslDistro: "Ubuntu", timeZone: "Asia/Tokyo" };
const NARROW_CTX = { ...WIDE_CTX, columns: 80 };

// SGR と OSC 8 を落として表示文字だけにする
const visible = (output) => {
  return output.replace(/\x1b\]8;;[^\x1b]*\x1b\\/g, "").replace(/\x1b\[[0-9;]*m/g, "");
};

const jst = (year, month, day, hour, minute) => {
  return Date.UTC(year, month - 1, day, hour - 9, minute) / 1000;
};

const WORKTREE_GIT = {
  root: `${HOME}/dev/sample-site-forms`,
  branch: "test/form-contract",
  worktree: { mainRepo: `${HOME}/dev/sample-site`, name: "sample-site-forms" },
};

const FULL_DATA = {
  transcript_path: `${HOME}/.claude-work/projects/-home-u-dev-x/abc.jsonl`,
  model: { id: "claude-opus-5[1m]", display_name: "Opus 5 (1M context)" },
  effort: { level: "xhigh" },
  workspace: { current_dir: `${HOME}/dev/sample-site-forms/src` },
  context_window: { used_percentage: 47, total_input_tokens: 470_000 },
  exceeds_200k_tokens: true,
  rate_limits: {
    five_hour: { used_percentage: 72.4, resets_at: jst(2026, 9, 18, 14, 30) },
    seven_day: { used_percentage: 18, resets_at: jst(2026, 9, 22, 18, 0) },
  },
  pr: { number: 207, url: "https://gitlab.example/g/p/-/merge_requests/207", review_state: "approved", kind: "mr" },
  thinking: { enabled: true },
  fast_mode: false,
  prompt_cache: { warm: true, caching_observed: true },
};

describe("render: 通常幅", () => {
  test("全項目ありで 2 行になる", () => {
    const output = render(FULL_DATA, { ...WIDE_CTX, git: WORKTREE_GIT });

    assert.equal(
      visible(output),
      [
        `[work] [Opus 5·1M][xhigh] ｜ ${DIR} ~/dev/sample-site ⌂ forms/src \u{E0A0} test/form-contract !207`,
        "⛁ █████░░░░░ 47% 470k ｜ 5h 72% →14:30 ｜ 7d 18%",
      ].join("\n"),
    );
  });

  test("場所は wsl.localhost の file リンク、MR は pr.url のリンクになる", () => {
    const output = render(FULL_DATA, { ...WIDE_CTX, git: WORKTREE_GIT });

    assert.match(output, /\x1b\]8;;file:\/\/wsl\.localhost\/Ubuntu\/home\/u\/dev\/sample-site-forms\/src\x1b\\/);
    assert.match(output, /\x1b\]8;;https:\/\/gitlab\.example\/g\/p\/-\/merge_requests\/207\x1b\\/);
  });

  test("WSL 外では素の file リンクになる", () => {
    const output = render(FULL_DATA, { ...WIDE_CTX, wslDistro: undefined, git: WORKTREE_GIT });

    assert.match(output, /\x1b\]8;;file:\/\/\/home\/u\/dev\/sample-site-forms\/src\x1b\\/);
  });

  test("200k 超えはトークン数が黄色、未満は dim", () => {
    const exceeded = render(FULL_DATA, WIDE_CTX);
    const within = render({ ...FULL_DATA, exceeds_200k_tokens: false }, WIDE_CTX);

    assert.match(exceeded, /\x1b\[33m470k/);
    assert.match(within, /\x1b\[2m470k/);
  });

  test("7d も 70% 以上なら日付付きのリセット時刻が付く", () => {
    const data = {
      ...FULL_DATA,
      rate_limits: { ...FULL_DATA.rate_limits, seven_day: { used_percentage: 82, resets_at: jst(2026, 9, 22, 18, 0) } },
    };

    assert.match(visible(render(data, WIDE_CTX)), /7d 82% →9\/22 18:00/);
  });

  test("70% 未満ならリセット時刻を出さない", () => {
    const data = { ...FULL_DATA, rate_limits: { five_hour: { used_percentage: 40, resets_at: jst(2026, 9, 18, 14, 30) } } };

    assert.match(visible(render(data, WIDE_CTX)), /5h 40%$/);
  });
});

describe("render: 狭い幅", () => {
  test("パスはリポ名、バーとリセット時刻を省く", () => {
    const output = render(FULL_DATA, { ...NARROW_CTX, git: WORKTREE_GIT });

    assert.equal(
      visible(output),
      [
        `[work] [Opus 5·1M][xhigh] ｜ ${DIR} sample-site ⌂ forms/src \u{E0A0} test/form-contract !207`,
        "⛁ 47% 470k ｜ 5h 72% ｜ 7d 18%",
      ].join("\n"),
    );
  });
});

describe("render: 欠損パターン", () => {
  test("空 JSON はモデル名の [?] だけ", () => {
    assert.equal(visible(render({}, WIDE_CTX)), "[?]");
  });

  test("used_percentage が null で rate_limits も無ければ 1 行目のみ", () => {
    const data = { ...FULL_DATA, context_window: { used_percentage: null }, rate_limits: undefined };
    const output = render(data, { ...WIDE_CTX, git: WORKTREE_GIT });

    assert.equal(output.includes("\n"), false);
    assert.doesNotMatch(visible(output), /⛁|5h|7d/);
  });

  test("既定プロファイル (.claude) は表示しない", () => {
    const data = { ...FULL_DATA, transcript_path: `${HOME}/.claude/projects/-home-u-dev-x/abc.jsonl` };

    assert.match(visible(render(data, WIDE_CTX)), /^\[Opus 5·1M\]\[xhigh\]/);
  });

  test("effort 無し・context 表記無しのモデル名はそのまま", () => {
    const data = { ...FULL_DATA, model: { display_name: "Sonnet 5" }, effort: undefined };

    assert.match(visible(render(data, WIDE_CTX)), /^\[work\] \[Sonnet 5\] ｜/);
  });

  test("git 情報が無ければ cwd を tildify してブランチは出さない", () => {
    const output = visible(render(FULL_DATA, WIDE_CTX));

    assert.match(output, new RegExp(`｜ ${DIR} ~/dev/sample-site-forms/src !207$`, "m"));
    assert.doesNotMatch(output, /\u{E0A0}/u);
  });

  test("worktree でない通常リポは ⌂ を付けない", () => {
    const git = { root: `${HOME}/dev/sample-site`, branch: "main" };
    const data = { ...FULL_DATA, workspace: { current_dir: `${HOME}/dev/sample-site/src` } };

    assert.match(visible(render(data, { ...WIDE_CTX, git })), new RegExp(`｜ ${DIR} ~/dev/sample-site/src \u{E0A0} main !207$`, "m"));
  });

  test("ghq 配下は root と host を落として owner/name にする", () => {
    const root = `${HOME}/ghq/gitlab.example.com/product/platform`;
    const data = { ...FULL_DATA, pr: undefined, workspace: { current_dir: `${root}/apps/portal` } };

    assert.match(
      visible(render(data, { ...WIDE_CTX, git: { root, branch: "main" } })),
      new RegExp(`｜ ${DIR} product/platform/apps/portal \u{E0A0} main$`, "m"),
    );
  });

  test("ghq 配下の worktree は owner/name ⌂ slug になる", () => {
    const mainRepo = `${HOME}/ghq/gitlab.example.com/product/platform`;
    const root = `${mainRepo}-portal`;
    const git = { root, branch: "cbfd659", worktree: { mainRepo, name: "platform-portal" } };
    const data = { ...FULL_DATA, pr: undefined, workspace: { current_dir: root } };

    assert.match(visible(render(data, { ...WIDE_CTX, git })), new RegExp(`｜ ${DIR} product/platform ⌂ portal \u{E0A0} cbfd659$`, "m"));
  });

  test("ghq root 直下の浅いパスは短縮せず tildify に戻す", () => {
    const data = { ...FULL_DATA, pr: undefined, workspace: { current_dir: `${HOME}/ghq/github.com` } };

    assert.match(visible(render(data, WIDE_CTX)), new RegExp(`｜ ${DIR} ~/ghq/github.com$`, "m"));
  });

  test("GitHub PR は # 表記", () => {
    const data = { ...FULL_DATA, pr: { number: 12, url: "https://github.com/o/r/pull/12" } };

    assert.match(visible(render(data, WIDE_CTX)), /#12$/m);
  });
});

describe("render: 異常系バッジ", () => {
  test("cache cold / fast / thinking off は 2 行目末尾に並ぶ", () => {
    const data = {
      ...FULL_DATA,
      prompt_cache: { warm: false, caching_observed: true },
      fast_mode: true,
      thinking: { enabled: false },
    };

    assert.match(visible(render(data, WIDE_CTX)), /7d 18% ｜ ❄ cache ⚡fast no-think$/);
  });

  test("caching_observed が false なら cold でも出さない", () => {
    const data = { ...FULL_DATA, prompt_cache: { warm: false, caching_observed: false } };

    assert.doesNotMatch(visible(render(data, WIDE_CTX)), /❄/);
  });
});

describe("readGitInfo", () => {
  const tmp = mkdtempSync(join(tmpdir(), "statusline-v2-"));
  const mainRepo = join(tmp, "repo");
  const siblingWorktree = join(tmp, "repo-forms");
  const innerWorktree = join(mainRepo, ".claude", "worktrees", "No.272");

  before(() => {
    mkdirSync(join(mainRepo, ".git", "worktrees", "repo-forms"), { recursive: true });
    mkdirSync(join(mainRepo, ".git", "worktrees", "No.272"), { recursive: true });
    mkdirSync(siblingWorktree, { recursive: true });
    mkdirSync(innerWorktree, { recursive: true });
    writeFileSync(join(mainRepo, ".git", "HEAD"), "ref: refs/heads/main\n");
    writeFileSync(join(mainRepo, ".git", "worktrees", "repo-forms", "HEAD"), "ref: refs/heads/test/form-contract\n");
    writeFileSync(join(mainRepo, ".git", "worktrees", "No.272", "HEAD"), "b2cc954f0e1d2c3b4a5968778695a4b3c2d1e0f9\n");
    writeFileSync(join(siblingWorktree, ".git"), `gitdir: ${join(mainRepo, ".git", "worktrees", "repo-forms")}\n`);
    writeFileSync(join(innerWorktree, ".git"), `gitdir: ${join(mainRepo, ".git", "worktrees", "No.272")}\n`);
  });

  after(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("通常リポ: サブディレクトリからでもルートとブランチが取れる", () => {
    assert.deepEqual(readGitInfo(join(mainRepo, "src", "pages")), { root: mainRepo, branch: "main", worktree: undefined });
  });

  test("兄弟ディレクトリ型 worktree", () => {
    assert.deepEqual(readGitInfo(join(siblingWorktree, "src")), {
      root: siblingWorktree,
      branch: "test/form-contract",
      worktree: { mainRepo, name: "repo-forms" },
    });
  });

  test("リポ内 (.claude/worktrees) 型 worktree、detached HEAD は短縮 SHA", () => {
    assert.deepEqual(readGitInfo(innerWorktree), {
      root: innerWorktree,
      branch: "b2cc954",
      worktree: { mainRepo, name: "No.272" },
    });
  });

  test("git 管理外なら undefined", () => {
    assert.equal(readGitInfo(tmp), undefined);
    assert.equal(readGitInfo(undefined), undefined);
  });
});
