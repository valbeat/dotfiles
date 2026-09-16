#!/usr/bin/env node
// 現在の Orca プロジェクト（repo）配下の worktree を横断し、自分以外のターミナルを閉じる。
// 稼働中のエージェントは閉じない。既定は dry-run。
//
// 判定ロジック（classify）は I/O から切り離してある。テストは classify だけを叩く。

import { execFile } from "node:child_process";
import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

export const DEFAULTS = {
  // エージェントを持たない素のシェルは、この秒数以上出力が無ければ閉じる
  shellIdleSecs: 60,
  // orca worktree ps の取得上限
  psLimit: 500,
};

// agents[].state のうち「閉じてよい」と明示的に判断できる値。
// ここに無い値（working、未知の新しい値）はすべて稼働中とみなす。
export const CLOSABLE_AGENT_STATES = new Set(["done"]);

// 画面にこれらが見えたら、エージェントの TUI が居座っているとみなす。
// worktree ps の agents[] に載らず agentIdentity も null の休眠セッションを
// 素のシェルと取り違えないための最後の防波堤。
export const AGENT_TUI_MARKERS = [
  /auto mode on/i,
  /shift\+tab to cycle/i,
  /\/clear to save/i,
  /esc to interrupt/i,
  /to interrupt\b/i,
  /\d[\d.,]*k? tokens\b/i,
  /⏵⏵/,
  /\bhuman\b.*\bassistant\b/i,
];

/** 画面の行配列がエージェント TUI に見えるか。判断材料が無ければ null（＝不明） */
export function looksLikeAgentTui(lines) {
  if (!Array.isArray(lines) || lines.length === 0) return null;
  const text = lines.join("\n");
  return AGENT_TUI_MARKERS.some((re) => re.test(text));
}

// ---------------------------------------------------------------------------
// 判定
// ---------------------------------------------------------------------------

export function paneKeyOf(terminal) {
  return `${terminal.tabId}:${terminal.leafId}`;
}

/**
 * @param {object} input
 * @param {Array} input.terminals   orca terminal list の terminals を worktree 横断で連結したもの
 * @param {Map<string, object>} input.agentByPaneKey  paneKey -> agents[] の要素
 * @param {object} input.self       { handle, paneKey } いずれも undefined 可
 * @param {Map<string, string[]>} [input.screenByHandle] handle -> 画面の行配列
 * @param {object} [input.opts]     { shellIdleSecs, keepShells, now }
 * @returns {Array<{terminal: object, action: "close"|"keep", reason: string}>}
 */
export function classify({ terminals, agentByPaneKey, self, screenByHandle, opts = {} }) {
  const shellIdleSecs = opts.shellIdleSecs ?? DEFAULTS.shellIdleSecs;
  const keepShells = opts.keepShells ?? false;
  const shellsOnly = opts.shellsOnly ?? false;
  const now = opts.now ?? Date.now();

  return terminals.map((terminal) => {
    const paneKey = paneKeyOf(terminal);

    // 1. 自分自身は絶対に閉じない
    if (self?.handle && terminal.handle === self.handle) {
      return { terminal, action: "keep", reason: "self" };
    }
    if (self?.paneKey && paneKey === self.paneKey) {
      return { terminal, action: "keep", reason: "self" };
    }

    const agent = agentByPaneKey.get(paneKey);

    // 2. エージェントが居るなら state で決める。既知の安全値以外はすべて残す
    if (agent) {
      if (agent.interrupted) {
        return { terminal, action: "keep", reason: `agent-interrupted (${agent.state})` };
      }
      // done は「終了」ではなく「プロンプトで待機中」。文脈を抱えたまま止まっている
      // ので、シェルだけ掃除したいときは --shells-only で丸ごと除外する。
      if (shellsOnly) {
        return { terminal, action: "keep", reason: `agent-${agent.state} (--shells-only)` };
      }
      if (CLOSABLE_AGENT_STATES.has(agent.state)) {
        return { terminal, action: "close", reason: `agent-${agent.state}` };
      }
      return { terminal, action: "keep", reason: `agent-${agent.state ?? "unknown"}` };
    }

    // 3. agents[] に載っていないが、画面にエージェント TUI が居座っている休眠セッション。
    //    worktree が inactive だと agents[] からも agentIdentity からも消えるので、
    //    ここを見ないと数十万トークンの文脈ごと素のシェル扱いで閉じてしまう。
    const tui = looksLikeAgentTui(screenByHandle?.get(terminal.handle));
    if (tui === null) {
      return { terminal, action: "keep", reason: "screen-unreadable" };
    }
    if (tui) {
      return { terminal, action: "keep", reason: "dormant-agent-tui" };
    }

    // 4. エージェントの居ない素のシェル
    if (keepShells) {
      return { terminal, action: "keep", reason: "shell (--keep-shells)" };
    }
    const lastOutputAt = terminal.lastOutputAt ?? 0;
    const idleSecs = Math.floor((now - lastOutputAt) / 1000);
    if (lastOutputAt && idleSecs < shellIdleSecs) {
      return { terminal, action: "keep", reason: `shell-active (${idleSecs}s前に出力)` };
    }
    return { terminal, action: "close", reason: "shell-idle" };
  });
}

/** 閉じた結果ターミナルが 0 になる worktree を返す（削除候補の母集団） */
export function emptiedWorktrees({ worktrees, decisions }) {
  const remaining = new Map(worktrees.map((w) => [w.id, 0]));
  for (const { terminal, action } of decisions) {
    if (action === "keep") {
      remaining.set(terminal.worktreeId, (remaining.get(terminal.worktreeId) ?? 0) + 1);
    }
  }
  return worktrees.filter((w) => !w.isMainWorktree && (remaining.get(w.id) ?? 0) === 0);
}

// ---------------------------------------------------------------------------
// orca CLI
// ---------------------------------------------------------------------------

async function orca(args) {
  const { stdout } = await execFileAsync("orca", [...args, "--json"], {
    maxBuffer: 64 * 1024 * 1024,
  });
  const parsed = JSON.parse(stdout);
  if (parsed.ok === false) {
    const code = parsed.error?.code ?? "unknown";
    throw new Error(`orca ${args.join(" ")} failed: ${code} ${parsed.error?.message ?? ""}`);
  }
  return parsed.result;
}

function selfContext() {
  const worktreeId = process.env.ORCA_WORKTREE_ID || "";
  const repoId = worktreeId.includes("::") ? worktreeId.split("::")[0] : "";
  return {
    handle: process.env.ORCA_TERMINAL_HANDLE || undefined,
    paneKey: process.env.ORCA_PANE_KEY || undefined,
    worktreeId: worktreeId || undefined,
    repoId: repoId || undefined,
  };
}

async function resolveRepoId(self, override) {
  if (override) return override.includes("::") ? override.split("::")[0] : override;
  if (self.repoId) return self.repoId;
  // Orca の外から実行された場合はカレントディレクトリから引く
  const result = await orca(["worktree", "current"]);
  const id = result?.worktree?.id ?? "";
  if (!id.includes("::")) throw new Error("現在のディレクトリが Orca 管理下の worktree ではない");
  return id.split("::")[0];
}

async function gitPorcelain(cwd) {
  try {
    const { stdout } = await execFileAsync("git", ["status", "--porcelain"], { cwd });
    return stdout.trim();
  } catch {
    return null;
  }
}

async function unpushedCount(cwd) {
  // `@{upstream}` は使わない。PR がマージされてリモートブランチが消えると
  // remote-tracking ref も消え、upstream 設定が残っていても解決に失敗するため
  // （「push 済みなのに未 push 扱い」になる）。どのリモート追跡 ref からも
  // 到達できないコミット数を数えれば、upstream 設定の有無に依存しない。
  try {
    const { stdout } = await execFileAsync(
      "git",
      ["rev-list", "--count", "HEAD", "--not", "--remotes"],
      { cwd },
    );
    return Number(stdout.trim());
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const opts = {
    apply: false,
    keepShells: false,
    shellIdleSecs: DEFAULTS.shellIdleSecs,
    json: false,
    forceNoSelf: false,
    shellsOnly: false,
    repo: undefined,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--apply") opts.apply = true;
    else if (arg === "--keep-shells") opts.keepShells = true;
    else if (arg === "--shells-only") opts.shellsOnly = true;
    else if (arg === "--json") opts.json = true;
    else if (arg === "--force-no-self") opts.forceNoSelf = true;
    else if (arg === "--shell-idle-secs") opts.shellIdleSecs = Number(argv[++i]);
    else if (arg === "--repo") opts.repo = argv[++i];
    else throw new Error(`unknown option: ${arg}`);
  }
  return opts;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const self = selfContext();

  if (!self.handle && !self.paneKey && opts.apply && !opts.forceNoSelf) {
    throw new Error(
      "ORCA_TERMINAL_HANDLE / ORCA_PANE_KEY が無い（Orca の外から実行された）。" +
        "自分自身を除外できないため --apply を拒否する。意図的なら --force-no-self を付ける。",
    );
  }

  const repoId = await resolveRepoId(self, opts.repo);
  const { worktrees } = await orca(["worktree", "list", "--repo", `id:${repoId}`]);

  // worktree ps から paneKey -> agent を作る
  const ps = await orca(["worktree", "ps", "--limit", String(DEFAULTS.psLimit)]);
  const agentByPaneKey = new Map();
  for (const row of ps.worktrees ?? []) {
    if (row.repoId !== repoId) continue;
    for (const agent of row.agents ?? []) {
      if (agent.paneKey) agentByPaneKey.set(agent.paneKey, agent);
    }
  }

  const terminals = [];
  for (const worktree of worktrees) {
    const result = await orca(["terminal", "list", "--worktree", `id:${worktree.id}`]);
    terminals.push(...(result.terminals ?? []));
  }

  // agents[] に載っていないターミナルだけ、画面を読んで休眠 TUI かどうかを見る。
  // --screen を付けないと再描画が積み重なった履歴が返り、判定に使えない。
  const screenByHandle = new Map();
  for (const terminal of terminals) {
    if (agentByPaneKey.has(paneKeyOf(terminal))) continue;
    if (self.handle && terminal.handle === self.handle) continue;
    try {
      const result = await orca([
        "terminal", "read",
        "--terminal", terminal.handle,
        "--screen", "--limit", "40",
      ]);
      const tail = result?.terminal?.tail;
      if (Array.isArray(tail)) screenByHandle.set(terminal.handle, tail);
    } catch {
      // 読めなければ screenByHandle に入れない = classify 側で keep に倒れる
    }
  }

  const decisions = classify({
    terminals,
    agentByPaneKey,
    self,
    screenByHandle,
    opts: {
      shellIdleSecs: opts.shellIdleSecs,
      keepShells: opts.keepShells,
      shellsOnly: opts.shellsOnly,
    },
  });

  const toClose = decisions.filter((d) => d.action === "close");
  const closed = [];
  const failed = [];

  if (opts.apply) {
    for (const { terminal } of toClose) {
      try {
        // ペイン単位で閉じる。--tab はタブ全体を落とすので、分割タブの中に
        // 「残す」と判定した稼働中ペインが同居していると巻き添えにする。
        // 全ペインを個別に閉じればタブはそのうち消えるので --tab は使わない。
        await orca(["terminal", "close", "--terminal", terminal.handle]);
        closed.push(terminal.handle);
      } catch (error) {
        failed.push({ handle: terminal.handle, error: String(error.message ?? error) });
      }
    }
  }

  // 空になる worktree の削除候補（提案のみ。実際の削除はしない）
  const candidates = [];
  for (const worktree of emptiedWorktrees({ worktrees, decisions })) {
    const dirty = await gitPorcelain(worktree.path);
    const unpushed = await unpushedCount(worktree.path);
    candidates.push({
      path: worktree.path,
      branch: worktree.branch,
      dirty: dirty === null ? "unknown" : dirty.length > 0,
      unpushed: unpushed === null ? "unknown" : unpushed,
      safeToRemove: dirty === "" && unpushed === 0,
    });
  }

  const report = {
    repoId,
    dryRun: !opts.apply,
    worktrees: worktrees.length,
    terminals: terminals.length,
    decisions: decisions.map(({ terminal, action, reason }) => ({
      action,
      reason,
      handle: terminal.handle,
      title: terminal.title,
      agentIdentity: terminal.agentIdentity ?? null,
      worktreePath: terminal.worktreePath,
      preview: terminal.preview ?? "",
    })),
    closed,
    failed,
    worktreeRemovalCandidates: candidates,
  };

  if (opts.json) {
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
    return;
  }

  printReport(report, opts);
}

function printReport(report, opts) {
  const { decisions } = report;
  const close = decisions.filter((d) => d.action === "close");
  const keep = decisions.filter((d) => d.action === "keep");

  console.log(
    `repo=${report.repoId} worktree=${report.worktrees} terminal=${report.terminals} ` +
      `${report.dryRun ? "(dry-run)" : "(apply)"}`,
  );
  console.log("");

  const row = (d) =>
    `  ${d.agentIdentity ?? "shell"}  ${d.title || "(no title)"}\n` +
    `      ${d.worktreePath}\n` +
    `      理由: ${d.reason}${d.preview ? `  / ${d.preview}` : ""}`;

  console.log(`閉じる (${close.length}):`);
  if (close.length === 0) console.log("  なし");
  else close.forEach((d) => console.log(row(d)));

  console.log("");
  console.log(`残す (${keep.length}):`);
  if (keep.length === 0) console.log("  なし");
  else keep.forEach((d) => console.log(row(d)));

  if (report.closed.length) {
    console.log("");
    console.log(`閉じた: ${report.closed.length} 件`);
  }
  if (report.failed.length) {
    console.log("");
    console.log("失敗:");
    report.failed.forEach((f) => console.log(`  ${f.handle}: ${f.error}`));
  }

  if (report.worktreeRemovalCandidates.length) {
    console.log("");
    console.log("ターミナルが空になる worktree（削除は実行しない。提案のみ）:");
    for (const c of report.worktreeRemovalCandidates) {
      const mark = c.safeToRemove ? "削除可" : "要確認";
      console.log(`  [${mark}] ${c.path}`);
      console.log(`      branch=${c.branch} dirty=${c.dirty} unpushed=${c.unpushed}`);
    }
    console.log("");
    console.log("  まとめて掃除するなら worktree-gc スキルを使う:");
    console.log("    node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs");
  }

  if (report.dryRun && close.length > 0) {
    console.log("");
    console.log("実際に閉じるには --apply を付ける。");
  }
  void opts;
}

// argv[1] はシンボリックリンクのままのパスで来るが、import.meta.url は Node が
// 解決した実パスになる。~/.claude が dotfiles への symlink なので、素朴に文字列比較すると
// 直接実行しても一致せず、main() が呼ばれないまま exit 0 で終わる。
const isDirectRun =
  process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
if (isDirectRun) {
  main().catch((error) => {
    console.error(String(error.message ?? error));
    process.exit(1);
  });
}
