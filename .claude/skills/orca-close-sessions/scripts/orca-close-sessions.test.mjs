import test from "node:test";
import assert from "node:assert/strict";

import {
  classify,
  emptiedWorktrees,
  paneKeyOf,
  CLOSABLE_AGENT_STATES,
} from "./orca-close-sessions.mjs";

const NOW = 1_700_000_000_000;

function terminal(overrides = {}) {
  return {
    handle: "term_x",
    tabId: "tab",
    leafId: "leaf",
    worktreeId: "repo::/w",
    worktreePath: "/w",
    title: "t",
    lastOutputAt: NOW - 3_600_000,
    ...overrides,
  };
}

function run(terminals, agents = [], self = {}, opts = {}) {
  const agentByPaneKey = new Map(agents.map((a) => [a.paneKey, a]));
  return classify({ terminals, agentByPaneKey, self, opts: { now: NOW, ...opts } });
}

test("paneKey は tabId:leafId", () => {
  assert.equal(paneKeyOf(terminal({ tabId: "a", leafId: "b" })), "a:b");
});

test("自分自身は handle 一致で残す", () => {
  const t = terminal({ handle: "term_self" });
  const [d] = run([t], [], { handle: "term_self" });
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "self");
});

test("自分自身は paneKey 一致でも残す（handle が取れない場合の保険）", () => {
  const t = terminal({ tabId: "a", leafId: "b", handle: "term_other" });
  const [d] = run([t], [], { paneKey: "a:b" });
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "self");
});

test("稼働中のエージェントは閉じない", () => {
  const t = terminal({ tabId: "a", leafId: "b" });
  const [d] = run([t], [{ paneKey: "a:b", state: "working" }]);
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "agent-working");
});

test("done のエージェントは閉じる", () => {
  const t = terminal({ tabId: "a", leafId: "b" });
  const [d] = run([t], [{ paneKey: "a:b", state: "done" }]);
  assert.equal(d.action, "close");
  assert.equal(d.reason, "agent-done");
});

test("未知の state は稼働中扱いで残す", () => {
  const t = terminal({ tabId: "a", leafId: "b" });
  const [d] = run([t], [{ paneKey: "a:b", state: "compacting-brand-new-state" }]);
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "agent-compacting-brand-new-state");
});

test("state が欠落していても残す", () => {
  const t = terminal({ tabId: "a", leafId: "b" });
  const [d] = run([t], [{ paneKey: "a:b" }]);
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "agent-unknown");
});

test("interrupted なエージェントは done でも残す", () => {
  const t = terminal({ tabId: "a", leafId: "b" });
  const [d] = run([t], [{ paneKey: "a:b", state: "done", interrupted: true }]);
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "agent-interrupted (done)");
});

test("エージェントの居ないシェルは十分古ければ閉じる", () => {
  const [d] = run([terminal({ lastOutputAt: NOW - 120_000 })]);
  assert.equal(d.action, "close");
  assert.equal(d.reason, "shell-idle");
});

test("直近に出力したシェルは残す", () => {
  const [d] = run([terminal({ lastOutputAt: NOW - 5_000 })]);
  assert.equal(d.action, "keep");
  assert.match(d.reason, /^shell-active/);
});

test("shellIdleSecs は閾値を動かす", () => {
  const t = terminal({ lastOutputAt: NOW - 30_000 });
  assert.equal(run([t], [], {}, { shellIdleSecs: 60 })[0].action, "keep");
  assert.equal(run([t], [], {}, { shellIdleSecs: 10 })[0].action, "close");
});

test("--keep-shells はシェルを一切閉じない", () => {
  const [d] = run([terminal({ lastOutputAt: 0 })], [], {}, { keepShells: true });
  assert.equal(d.action, "keep");
});

test("lastOutputAt が無いシェルは閉じる", () => {
  const [d] = run([terminal({ lastOutputAt: null })]);
  assert.equal(d.action, "close");
});

test("self 判定はエージェント判定より優先される", () => {
  const t = terminal({ tabId: "a", leafId: "b", handle: "term_self" });
  const [d] = run([t], [{ paneKey: "a:b", state: "done" }], { handle: "term_self" });
  assert.equal(d.action, "keep");
  assert.equal(d.reason, "self");
});

test("CLOSABLE_AGENT_STATES は許可リストであって拒否リストではない", () => {
  assert.ok(CLOSABLE_AGENT_STATES.has("done"));
  assert.ok(!CLOSABLE_AGENT_STATES.has("working"));
});

test("emptiedWorktrees はターミナルが残る worktree を除く", () => {
  const worktrees = [
    { id: "r::/main", path: "/main", isMainWorktree: true },
    { id: "r::/a", path: "/a", isMainWorktree: false },
    { id: "r::/b", path: "/b", isMainWorktree: false },
  ];
  const decisions = [
    { terminal: terminal({ worktreeId: "r::/a" }), action: "close" },
    { terminal: terminal({ worktreeId: "r::/b" }), action: "keep" },
  ];
  const result = emptiedWorktrees({ worktrees, decisions });
  assert.deepEqual(result.map((w) => w.path), ["/a"]);
});

test("emptiedWorktrees はメインのチェックアウトを候補にしない", () => {
  const worktrees = [{ id: "r::/main", path: "/main", isMainWorktree: true }];
  const result = emptiedWorktrees({ worktrees, decisions: [] });
  assert.deepEqual(result, []);
});

test("ターミナルが最初から 0 の worktree も候補になる", () => {
  const worktrees = [{ id: "r::/a", path: "/a", isMainWorktree: false }];
  const result = emptiedWorktrees({ worktrees, decisions: [] });
  assert.deepEqual(result.map((w) => w.path), ["/a"]);
});
