import assert from 'node:assert/strict'
import { mkdtempSync, utimesSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, it } from 'node:test'

import {
  classifyWorktree,
  DEFAULTS,
  parseArgs,
  parseDefaultBranch,
  parseWorktreeList,
  readWorktreeTouchedAt,
  resolveLastActivityDays,
  summarize,
} from './worktree-gc.mjs'

/** テスト用の worktree 情報を組み立てるヘルパ（既定は「空の使い捨て worktree」） */
const wt = (overrides = {}) => ({
  path: '/repo/.claude/worktrees/agent-x',
  branch: 'claude/agent-x',
  isMain: false,
  isLocked: false,
  dirtyCount: 0,
  untrackedCount: 0,
  aheadOfMain: 0,
  hasRemoteBranch: false,
  lastActivityDays: 30,
  sizeKb: 1024 * 1024,
  pr: null,
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
      wt({ aheadOfMain: 2, hasRemoteBranch: false }),
      DEFAULTS,
    )
    assert.equal(r.verdict, 'hold')
    assert.match(r.reason, /未 push/)
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
