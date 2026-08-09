#!/usr/bin/env node
import { homedir } from "os";
import { dirname, basename } from "path";
import { text } from "stream/consumers";

const ANSI = {
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  green: "\x1b[32m",
  reset: "\x1b[0m",
};
const DANGER_PERCENT = 90;
const WARN_PERCENT = 70;

const main = async () => {
  const raw = await text(process.stdin);
  process.stdout.write(render(safeParse(raw)));
};

const render = (data) => {
  const profile = getProfile(data?.transcript_path);
  const model = data?.model?.display_name ?? "?";
  const cwd = tildify(data?.workspace?.current_dir ?? data?.cwd ?? "");
  const fiveH = data?.rate_limits?.five_hour?.used_percentage;
  const sevenD = data?.rate_limits?.seven_day?.used_percentage;
  const metrics = [
    formatPercent("⛁", data?.context_window?.used_percentage),
    formatPercent("5h", fiveH),
    formatPercent("7d", sevenD),
  ].filter((m) => {
    return m !== undefined;
  });
  const head = `${getPrefix(profile)}[${model}]  ${cwd}`;

  if (metrics.length === 0) {
    return head;
  }

  return `${head} ｜ ${metrics.join(" ｜ ")}`;
};

const getPrefix = (profile) => {
  if (profile === undefined) {
    return "";
  }

  return `[${profile}] `;
};

const getProfile = (transcriptPath) => {
  if (transcriptPath === undefined || transcriptPath === "") {
    return undefined;
  }

  // transcript_path: <CONFIG_DIR>/projects/<encoded-cwd>/<session>.jsonl の構造で、3階層上が CONFIG_DIR
  const configDir = dirname(dirname(dirname(transcriptPath)));
  const name = basename(configDir).replace(/^\./, "");

  if (name === "") {
    return undefined;
  }

  return name;
};

const tildify = (path) => {
  const home = homedir();

  if (path.startsWith(home)) {
    return `~${path.slice(home.length)}`;
  }

  return path;
};

const formatPercent = (label, percent) => {
  if (!isPercent(percent)) {
    return undefined;
  }

  const rounded = Math.round(percent);
  return `${label} ${getColor(rounded)}${rounded}%${ANSI.reset}`;
};

const getColor = (percent) => {
  if (percent >= DANGER_PERCENT) {
    return ANSI.red;
  }

  if (percent >= WARN_PERCENT) {
    return ANSI.yellow;
  }

  return ANSI.green;
};

const isPercent = (value) => {
  return typeof value === "number" && isFinite(value);
};

const safeParse = (input) => {
  try {
    return JSON.parse(input);
  } catch {
    return {};
  }
};

main().catch(() => {
  process.exit(0);
});
