import assert from 'node:assert/strict'
import { mkdtempSync, utimesSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, it } from 'node:test'

import {
  buildOrcaIndex,
  classifyWorktree,
  DEFAULTS,
  isBusyTitle,
  parseArgs,
  parseDefaultBranch,
  parseWorktreeList,
  prLookupBranch,
  readWorktreeTouchedAt,
  resolveLastActivityDays,
  summarize,
  summarizeTerminals,
} from './worktree-gc.mjs'

/** テスト用の worktree 情報を組み立てるヘルパ（既定は「空の使い捨て worktree」） */
const wt = (overrides = {}) => ({
  path: '/repo/.claude/worktrees/agent-x',
  branch: 'claude/agent-x',
  isMain: false,
  isBaseBranch: false,
  isLocked: false,
  dirtyCount: 0,
  untrackedCount: 0,
  aheadOfMain: 0,
  unpushedCount: 0,
  hasRemoteBranch: false,
  lastActivityDays: 30,
  sizeKb: 1024 * 1024,
  pr: null,
  orca: null,
  ...overrides,
})

/** Orca のワークスペース情報（既定は「既定 status で、誰も使っていない」） */
const orca = (overrides = {}) => ({
  status: 'in-progress',
  isPinned: false,
  isArchived: false,
  isUnread: false,
  automation: null,
  terminals: { live: 0, busy: 0, agents: [] },
  ...overrides,
})

describe('classifyWorktree - 保護', () => {
  it('メインのチェックアウトは常に keep', () => {
    const r = classifyWorktree(wt({ isMain: true, dirtyCount: 5 }), DEFAULTS)
    assert.equal(r.verdict, 'keep')
    assert.equal(r.deleteBranch, false)
  })

  it('locked な worktree は keep', () => {
    const r = classifyWorktree(wt({ isLocked: true }), DEFAULTS)
    assert.equal(r.verdict, 'keep')
  })
})

describe('classifyWorktree - 未コミット変更', () => {
  it('追跡ファイルに変更があれば hold', () => {
    const r = classifyWorktree(wt({ dirtyCount: 3 }), DEFAULTS)
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /未コミット変更/)
  })

  it('未追跡ファイルだけでも hold', () => {
    const r = classifyWorktree(wt({ untrackedCount: 1 }), DEFAULTS)
    assert.equal(r.verdict, 'hold')
  })

  it('PR がマージ済みでも未コミット変更があれば hold が優先される', () => {
    const r = classifyWorktree(
      wt({ dirtyCount: 1, pr: { number: 1, state: 'MERGED', ageDays: 90 } }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
  })
})

describe('classifyWorktree - OPEN な PR', () => {
  it('更新が新しい OPEN PR は keep', () => {
    const r = classifyWorktree(
      wt({ pr: { number: 8152, state: 'OPEN', ageDays: 2 } }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
    assert.match(r.reason, /#8152/)
  })

  it('停滞した OPEN PR は slim（node_modules のみ削除）', () => {
    const r = classifyWorktree(
      wt({
        pr: { number: 8152, state: 'OPEN', ageDays: DEFAULTS.staleOpenDays },
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'slim')
    assert.equal(r.deleteBranch, false)
  })
})

describe('classifyWorktree - 閉じた PR', () => {
  it('MERGED から猶予を過ぎたら delete + ブランチも削除', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 10,
        pr: {
          number: 8156,
          state: 'MERGED',
          ageDays: DEFAULTS.mergedGraceDays,
        },
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, true)
  })

  it('MERGED でも猶予内なら keep', () => {
    const r = classifyWorktree(
      wt({ pr: { number: 8178, state: 'MERGED', ageDays: 0 } }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
  })

  it('CLOSED（未マージ）は worktree だけ消してブランチは残す', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 4,
        pr: { number: 7000, state: 'CLOSED', ageDays: 30 },
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, false)
  })
})

describe('classifyWorktree - PR なし', () => {
  it('独自コミットが 0 なら delete（ブランチも削除して良い）', () => {
    const r = classifyWorktree(wt({ aheadOfMain: 0 }), DEFAULTS)
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, true)
  })

  it('作りたて（猶予内）は keep', () => {
    const r = classifyWorktree(
      wt({ aheadOfMain: 0, lastActivityDays: 0 }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
  })

  it('push 済みの独自コミットがあれば hold', () => {
    const r = classifyWorktree(
      wt({ aheadOfMain: 2, hasRemoteBranch: true }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
  })

  it('未 push の独自コミットは hold にして警告を出す', () => {
    const r = classifyWorktree(
      wt({ aheadOfMain: 2, unpushedCount: 2, hasRemoteBranch: false }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /未 push/)
  })

  it('基準ブランチ（main）を checkout した空の worktree は、木だけ消してブランチは残す', () => {
    const r = classifyWorktree(
      wt({ branch: 'main', isBaseBranch: true, aheadOfMain: 0 }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, false)
  })

  it('completed でも基準ブランチは消さない', () => {
    const r = classifyWorktree(
      wt({
        branch: 'main',
        isBaseBranch: true,
        orca: orca({ status: 'completed' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.deleteBranch, false)
  })

  it('detached HEAD ではブランチ削除を要求しない', () => {
    const r = classifyWorktree(wt({ branch: null, aheadOfMain: 0 }), DEFAULTS)
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, false)
  })
})

describe('resolveLastActivityDays', () => {
  const now = Date.parse('2026-08-03T02:00:00Z')
  const daysAgo = n => new Date(now - n * 86_400_000).toISOString()

  it('与えられた時刻のうち最も新しいものを採る', () => {
    const days = resolveLastActivityDays(
      {
        lastCommitIso: daysAgo(30),
        prUpdatedAtIso: daysAgo(5),
        worktreeTouchedIso: daysAgo(12),
      },
      now,
    )
    assert.equal(days, 5)
  })

  it('作りたての worktree は、ベースのコミットが古くても新しいと判定する', () => {
    // 稼働中のセッションが古い main から生やした worktree を消さないための保険
    const days = resolveLastActivityDays(
      {
        lastCommitIso: daysAgo(3),
        prUpdatedAtIso: null,
        worktreeTouchedIso: daysAgo(0),
      },
      now,
    )
    assert.equal(days, 0)
  })

  it('null は無視する', () => {
    const days = resolveLastActivityDays(
      {
        lastCommitIso: daysAgo(7),
        prUpdatedAtIso: null,
        worktreeTouchedIso: null,
      },
      now,
    )
    assert.equal(days, 7)
  })

  it('手がかりが何も無ければ無限大（＝古い扱い）', () => {
    const days = resolveLastActivityDays(
      { lastCommitIso: null, prUpdatedAtIso: null, worktreeTouchedIso: null },
      now,
    )
    assert.equal(days, Number.POSITIVE_INFINITY)
  })
})

describe('readWorktreeTouchedAt', () => {
  const fixture = files => {
    const dir = mkdtempSync(join(tmpdir(), 'wt-gc-'))
    for (const [name, epochMs] of Object.entries(files)) {
      const path = join(dir, name)
      writeFileSync(path, '')
      utimesSync(path, epochMs / 1000, epochMs / 1000)
    }
    return dir
  }
  const at = iso => Date.parse(iso)

  it('gitdir と HEAD の新しい方を返す', () => {
    const dir = fixture({
      gitdir: at('2026-07-05T00:00:00Z'),
      HEAD: at('2026-07-25T00:00:00Z'),
    })
    assert.equal(
      readWorktreeTouchedAt(dir),
      new Date(at('2026-07-25T00:00:00Z')).toISOString(),
    )
  })

  it('index は見ない（git status が書き戻して mtime が今になるため）', () => {
    const dir = fixture({
      gitdir: at('2026-07-05T00:00:00Z'),
      HEAD: at('2026-07-05T00:00:00Z'),
      index: at('2026-08-03T00:00:00Z'),
    })
    assert.equal(
      readWorktreeTouchedAt(dir),
      new Date(at('2026-07-05T00:00:00Z')).toISOString(),
    )
  })

  it('読めなければ null', () => {
    assert.equal(
      readWorktreeTouchedAt(join(tmpdir(), 'wt-gc-does-not-exist')),
      null,
    )
    assert.equal(readWorktreeTouchedAt(''), null)
  })
})

describe('parseArgs', () => {
  it('既定は dry-run', () => {
    const o = parseArgs([])
    assert.equal(o.apply, false)
    assert.equal(o.json, false)
    assert.equal(o.mergedGraceDays, DEFAULTS.mergedGraceDays)
  })

  it('閾値を上書きでき、値をフラグとして誤解しない', () => {
    const o = parseArgs([
      '--merged-grace',
      '7',
      '--apply',
      '--stale-open',
      '30',
    ])
    assert.equal(o.mergedGraceDays, 7)
    assert.equal(o.staleOpenDays, 30)
    assert.equal(o.apply, true)
  })

  it('日数が無い閾値フラグは弾く', () => {
    assert.throws(() => parseArgs(['--merged-grace', '--apply']), /日数/)
  })

  it('サイズ計測は既定で行わない（du が node_modules を走査して遅いため）', () => {
    assert.equal(parseArgs([]).size, false)
    assert.equal(parseArgs(['--size']).size, true)
  })
})

describe('parseDefaultBranch', () => {
  it('origin/HEAD の指す先からブランチ名を取り出す', () => {
    assert.equal(parseDefaultBranch('refs/remotes/origin/main'), 'main')
    assert.equal(parseDefaultBranch('refs/remotes/origin/master'), 'master')
  })

  it('スラッシュを含むブランチ名も落とさない', () => {
    assert.equal(parseDefaultBranch('refs/remotes/origin/release/v2'), 'release/v2')
  })

  it('取得できなければ null（呼び出し側で候補を順に試す）', () => {
    assert.equal(parseDefaultBranch(''), null)
    assert.equal(parseDefaultBranch('fatal: ref refs/remotes/origin/HEAD is not'), null)
  })
})

describe('parseWorktreeList', () => {
  it('branch / detached / locked を読み分ける', () => {
    const output = [
      'worktree /repo',
      'HEAD abc',
      'branch refs/heads/main',
      '',
      'worktree /repo/.claude/worktrees/a',
      'HEAD def',
      'detached',
      '',
      'worktree /repo/.claude/worktrees/b',
      'HEAD ghi',
      'branch refs/heads/feat/x',
      'locked',
      '',
    ].join('\n')
    const entries = parseWorktreeList(output)
    assert.equal(entries.length, 3)
    assert.equal(entries[0].branch, 'main')
    assert.equal(entries[1].branch, null)
    assert.equal(entries[2].branch, 'feat/x')
    assert.equal(entries[2].isLocked, true)
    assert.equal(entries[0].isLocked, false)
  })
})

describe('summarize', () => {
  it('判定ごとの件数と解放見込みを集計する', () => {
    const rows = [
      { verdict: 'delete', sizeKb: 1024 * 1024 },
      { verdict: 'delete', sizeKb: 1024 * 1024 },
      { verdict: 'slim', sizeKb: 1024 * 1024 },
      { verdict: 'keep', sizeKb: 1024 * 1024 },
      { verdict: 'hold', sizeKb: 1024 * 1024 },
    ]
    const s = summarize(rows)
    assert.equal(s.counts.delete, 2)
    assert.equal(s.counts.slim, 1)
    assert.equal(s.counts.keep, 1)
    assert.equal(s.counts.hold, 1)
    // delete は全量、slim は node_modules 相当のみ解放される
    assert.ok(s.freedGb > 2 && s.freedGb < 3)
  })
})

describe('classifyWorktree - Orca の保護', () => {
  it('自動化の固定ワークスペースは、空で古くても keep', () => {
    const r = classifyWorktree(
      wt({ branch: null, orca: orca({ automation: 'PR 保守' }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
    assert.match(r.reason, /自動化/)
  })

  it('ピン留めされたワークスペースは keep', () => {
    const r = classifyWorktree(wt({ orca: orca({ isPinned: true }) }), DEFAULTS)
    assert.equal(r.verdict, 'keep')
  })

  it('エージェントが作業中なら、PR がマージ済みでも keep', () => {
    const r = classifyWorktree(
      wt({
        pr: { number: 1, state: 'MERGED', ageDays: 90 },
        orca: orca({ terminals: { live: 1, busy: 1, agents: ['codex'] } }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
    assert.match(r.reason, /作業中/)
  })

  it('待機中のターミナルが開いているだけなら削除を妨げない', () => {
    const r = classifyWorktree(
      wt({ orca: orca({ terminals: { live: 2, busy: 0, agents: ['codex'] } }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
  })

  it('未読の出力があれば hold（最終レポートを読む前に消さない）', () => {
    const r = classifyWorktree(
      wt({
        pr: { number: 1, state: 'MERGED', ageDays: 90 },
        orca: orca({ isUnread: true }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /未読/)
  })

  it('未コミット変更は status が completed でも hold', () => {
    const r = classifyWorktree(
      wt({ dirtyCount: 1, orca: orca({ status: 'completed' }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
  })
})

describe('classifyWorktree - Orca の status', () => {
  it('completed は OPEN な PR があっても削除する（ブランチは残す）', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 3,
        hasRemoteBranch: true,
        pr: { number: 2, state: 'OPEN', ageDays: 0 },
        orca: orca({ status: 'completed' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, false)
    assert.match(r.reason, /completed/)
  })

  it('completed は MERGED の猶予を待たずに削除し、ブランチも消す', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 3,
        pr: { number: 2, state: 'MERGED', ageDays: 0 },
        orca: orca({ status: 'completed' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, true)
  })

  it('completed でも、PR なしの未 push コミットがあれば hold', () => {
    const r = classifyWorktree(
      wt({ aheadOfMain: 2, unpushedCount: 2, orca: orca({ status: 'completed' }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /未 push/)
  })

  it('completed で空なら作りたてでも削除する', () => {
    const r = classifyWorktree(
      wt({ lastActivityDays: 0, orca: orca({ status: 'completed' }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, true)
  })

  it('archived は completed と同じ扱い', () => {
    const r = classifyWorktree(
      wt({ lastActivityDays: 0, orca: orca({ isArchived: true }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
  })

  it('todo の空ワークスペースは、古くても keep（着手待ち）', () => {
    const r = classifyWorktree(wt({ orca: orca({ status: 'todo' }) }), DEFAULTS)
    assert.equal(r.verdict, 'keep')
    assert.match(r.reason, /todo/)
  })

  it('in-review は PR が閉じるまで delete にしない', () => {
    const r = classifyWorktree(
      wt({ orca: orca({ status: 'in-review' }) }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'keep')
  })

  it('in-review でも PR が MERGED なら従来どおり削除する', () => {
    const r = classifyWorktree(
      wt({
        pr: { number: 3, state: 'MERGED', ageDays: 10 },
        orca: orca({ status: 'in-review' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
  })

  it('既定の in-progress は判定に影響しない（全ワークスペースの既定値のため）', () => {
    const r = classifyWorktree(wt({ orca: orca() }), DEFAULTS)
    assert.equal(r.verdict, 'delete')
  })
})

describe('isBusyTitle', () => {
  it('codex / Claude Code の作業中スピナーを検出する', () => {
    assert.equal(isBusyTitle('⠹ auto-pr-ci-run-157-20...'), true)
    assert.equal(isBusyTitle('◑ Orcaのワークスペース'), true)
  })

  it('待機中の表示や普通のタイトルは busy にしない', () => {
    assert.equal(isBusyTitle('✳ 他のセッションを閉じて'), false)
    assert.equal(isBusyTitle('auto-pr-ci-run-156-20...'), false)
    assert.equal(isBusyTitle('~/orca/workspaces/techtrain-'), false)
    assert.equal(isBusyTitle(''), false)
    assert.equal(isBusyTitle(undefined), false)
  })
})

describe('summarizeTerminals', () => {
  it('orphaned を除いて件数・作業中・エージェントを数える', () => {
    const s = summarizeTerminals([
      { title: '⠹ run', agentIdentity: 'codex', orphaned: false },
      { title: 'run', agentIdentity: 'codex', orphaned: false },
      { title: '~/x', agentIdentity: null, orphaned: false },
      { title: '⠹ ghost', agentIdentity: 'claude', orphaned: true },
    ])
    assert.deepEqual(s, { live: 3, busy: 1, agents: ['codex'] })
  })
})

describe('buildOrcaIndex', () => {
  it('パスでワークスペースを引け、existing モードの自動化を紐づける', () => {
    const index = buildOrcaIndex({
      worktrees: [
        {
          path: '/ws/a',
          workspaceStatus: 'completed',
          isPinned: false,
          isArchived: false,
          isUnread: true,
        },
        { path: '/ws/fixed', workspaceStatus: 'in-progress' },
      ],
      automations: [
        { name: '固定', workspaceMode: 'existing', workspaceId: 'repo-1::/ws/fixed' },
        { name: '毎回新規', workspaceMode: 'new_per_run', workspaceId: null },
      ],
    })
    assert.deepEqual(index.get('/ws/a'), {
      status: 'completed',
      isPinned: false,
      isArchived: false,
      isUnread: true,
      automation: null,
    })
    assert.equal(index.get('/ws/fixed').automation, '固定')
    assert.equal(index.get('/ws/none'), undefined)
  })
})

describe('prLookupBranch', () => {
  it('基準ブランチでは PR を探さない（無関係な古い PR を拾うため）', () => {
    assert.equal(prLookupBranch('main', 'origin/main'), null)
    assert.equal(prLookupBranch('release/v2', 'origin/release/v2'), null)
  })

  it('それ以外のブランチはそのまま、detached は null', () => {
    assert.equal(prLookupBranch('feat/x', 'origin/main'), 'feat/x')
    assert.equal(prLookupBranch(null, 'origin/main'), null)
  })
})

describe('classifyWorktree - どのリモートにも無いコミット', () => {
  it('PR が MERGED でも、マージ後に積んだ未 push コミットがあれば hold', () => {
    // PR の state だけ見るとブランチごと消して、このコミットを失う
    const r = classifyWorktree(
      wt({
        aheadOfMain: 1,
        unpushedCount: 1,
        pr: { number: 8775, state: 'MERGED', ageDays: 10 },
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /リモートに無いコミット 1 件/)
  })

  it('completed でも、PR があって未 push コミットがあれば hold', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 3,
        unpushedCount: 1,
        hasRemoteBranch: true,
        pr: { number: 2, state: 'OPEN', ageDays: 0 },
        orca: orca({ status: 'completed' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
  })

  it('detached HEAD の未 push コミットも hold（ブランチにすら残らない）', () => {
    const r = classifyWorktree(
      wt({ branch: null, aheadOfMain: 2, unpushedCount: 2 }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
  })

  it('同名のリモートブランチが無くても、コミットが別のリモートにあれば未 push 扱いしない', () => {
    const r = classifyWorktree(
      wt({ aheadOfMain: 6, unpushedCount: 0, hasRemoteBranch: false }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.doesNotMatch(r.reason, /未 push/)
  })

  it('completed で、コミットがすべてリモートにあるなら PR なしでも削除する', () => {
    const r = classifyWorktree(
      wt({
        aheadOfMain: 6,
        unpushedCount: 0,
        orca: orca({ status: 'completed' }),
      }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'delete')
    assert.equal(r.deleteBranch, false)
  })
})
