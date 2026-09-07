#!/usr/bin/env node
// 使い終わった git worktree を状態ベースで判定して掃除するツール。
//
// 背景: エージェントを並列で走らせると worktree が溜まる。1 worktree あたり
// node_modules だけで 1.3GB あり、放置すると数十 GB を占める。
//
// 判定の設計:
//   - 「マージ済みか」は git の祖先判定では決められない。squash / rebase merge だと
//     ブランチのコミットが main の祖先にならないため。PR の state を正とする。
//   - worktree の削除とブランチの削除を分ける。worktree を消してもコミット済みの
//     作業はブランチの ref に残り、失われるのは未コミットの変更だけ。
//   - stash は common dir で共有されるため worktree を消しても失われない。
//   - ディレクトリの mtime はビルド生成物で動くので使わない。最終コミット日時 /
//     PR の更新日時 / worktree 管理ファイルの mtime のうち最も新しいものを
//     「最終アクティビティ」とする。管理ファイルを見るのは、古い main から生やした
//     ばかりの worktree を「放置」と誤判定しないため。
//
// 対象リポジトリの中で実行する。基準ブランチは origin/HEAD から検出する。
//
// 使い方:
//   node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs           判定結果を表示（何も消さない）
//   node ~/.claude/skills/worktree-gc/scripts/worktree-gc.mjs --apply   判定に従って実際に削除する
//   オプション:
//     --size          ディスク使用量も測る（du が node_modules を走査するので数十秒かかる）
//     --json          機械可読な出力
//     --merged-grace <日> / --stale-open <日> / --empty-grace <日>

import { execFileSync } from 'node:child_process'
import { existsSync, readdirSync, rmSync, statSync } from 'node:fs'
import { join } from 'node:path'

export const DEFAULTS = {
  /** PR が閉じてから worktree を消すまでの猶予 */
  mergedGraceDays: 3,
  /** OPEN な PR が何日更新されなければ node_modules を落とすか */
  staleOpenDays: 14,
  /** 独自コミットを持たない worktree を消すまでの猶予 */
  emptyGraceDays: 1,
}

/** worktree のうち node_modules が占める概算比率（解放見込みの計算に使う） */
const NODE_MODULES_RATIO = 0.93

/**
 * worktree の状態から処分を決める純粋関数。
 * 上から順に評価し、最初に一致した規則を適用する。
 *
 * verdict:
 *   keep   … 現役。触らない
 *   hold   … 消して良いか機械には決められない。人間に見せる
 *   slim   … node_modules だけ削除して木は残す
 *   delete … worktree を削除する（deleteBranch が true ならブランチも）
 */
export const classifyWorktree = (wt, options = DEFAULTS) => {
  const keep = reason => ({ verdict: 'keep', reason, deleteBranch: false })
  const hold = reason => ({ verdict: 'hold', reason, deleteBranch: false })

  if (wt.isMain) {
    return keep('メインのチェックアウト')
  }
  if (wt.isLocked) {
    return keep('locked')
  }

  // 未コミットの変更だけは worktree を消すと本当に失われるので、最優先で守る
  if (wt.dirtyCount > 0 || wt.untrackedCount > 0) {
    return hold(
      `未コミット変更 ${wt.dirtyCount} 件 / 未追跡 ${wt.untrackedCount} 件`,
    )
  }

  if (wt.pr && wt.pr.state === 'OPEN') {
    if (wt.pr.ageDays >= options.staleOpenDays) {
      return {
        verdict: 'slim',
        reason: `PR #${wt.pr.number} は OPEN だが ${wt.pr.ageDays} 日停滞`,
        deleteBranch: false,
      }
    }
    return keep(`PR #${wt.pr.number} は OPEN（${wt.pr.ageDays} 日前に更新）`)
  }

  if (wt.pr && (wt.pr.state === 'MERGED' || wt.pr.state === 'CLOSED')) {
    if (wt.pr.ageDays < options.mergedGraceDays) {
      return keep(
        `PR #${wt.pr.number} は ${wt.pr.state} だが猶予 ${options.mergedGraceDays} 日以内`,
      )
    }
    // MERGED なら成果は main にあるのでブランチも消せる。
    // CLOSED（未マージ）は成果がどこにも無いのでブランチは残す。
    const merged = wt.pr.state === 'MERGED'
    return {
      verdict: 'delete',
      reason: `PR #${wt.pr.number} が ${wt.pr.state} になってから ${wt.pr.ageDays} 日`,
      deleteBranch: merged && Boolean(wt.branch),
    }
  }

  // ここから先は PR が無い worktree
  if (wt.aheadOfMain === 0) {
    if (wt.lastActivityDays < options.emptyGraceDays) {
      return keep('作りたて')
    }
    return {
      verdict: 'delete',
      reason: 'PR なし・main からの独自コミットなし（空）',
      deleteBranch: Boolean(wt.branch),
    }
  }

  if (wt.hasRemoteBranch) {
    return hold(`PR なしだが push 済み（独自コミット ${wt.aheadOfMain} 件）`)
  }
  return hold(`未 push の独自コミット ${wt.aheadOfMain} 件 — 消すと失われる`)
}

/**
 * 判定結果の件数と解放見込みを集計する。
 * sizeKb は --size を付けたときだけ埋まるので、null は 0 として扱う。
 */
export const summarize = rows => {
  const counts = { keep: 0, hold: 0, slim: 0, delete: 0 }
  let freedKb = 0
  for (const row of rows) {
    counts[row.verdict] += 1
    if (row.verdict === 'delete') {
      freedKb += row.sizeKb ?? 0
    }
    if (row.verdict === 'slim') {
      freedKb += (row.sizeKb ?? 0) * NODE_MODULES_RATIO
    }
  }
  return { counts, freedGb: freedKb / 1024 / 1024 }
}

// ---------------------------------------------------------------------------
// 以下は git / gh を叩く I/O 層
// ---------------------------------------------------------------------------

const git = (args, cwd) => {
  try {
    return execFileSync('git', args, {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim()
  } catch {
    return ''
  }
}

const daysSince = (iso, now = Date.now()) => {
  if (!iso) {
    return Number.POSITIVE_INFINITY
  }
  return Math.floor((now - new Date(iso).getTime()) / 86_400_000)
}

/**
 * 「最後に動きがあったのはいつか」を決める。
 *
 * 最終コミット日時だけでは足りない。古い main から生やしたばかりの worktree は
 * ベースのコミットが古いため「放置された」と誤判定され、稼働中のセッションの
 * worktree を消してしまう。worktree の管理ファイルが触られた時刻も併せて見る。
 */
export const resolveLastActivityDays = (
  { lastCommitIso, prUpdatedAtIso, worktreeTouchedIso },
  now = Date.now(),
) =>
  Math.min(
    daysSince(lastCommitIso, now),
    daysSince(prUpdatedAtIso, now),
    daysSince(worktreeTouchedIso, now),
  )

/** `git worktree list --porcelain` を構造化する */
export const parseWorktreeList = output => {
  const entries = []
  let current = null
  for (const line of output.split(/\r?\n/)) {
    if (line.startsWith('worktree ')) {
      current = {
        path: line.slice('worktree '.length),
        branch: null,
        isLocked: false,
      }
      entries.push(current)
    } else if (current && line.startsWith('branch ')) {
      current.branch = line.slice('branch refs/heads/'.length)
    } else if (current && line.startsWith('locked')) {
      current.isLocked = true
    }
  }
  return entries
}

/**
 * `git symbolic-ref refs/remotes/origin/HEAD` の出力から既定ブランチ名を取り出す。
 * 取得できなければ null（呼び出し側で main → master の順に候補を試す）。
 */
export const parseDefaultBranch = output => {
  const match = /^refs\/remotes\/origin\/(.+)$/.exec((output || '').trim())
  return match ? match[1] : null
}

/** 比較の基準にするリモート追跡ブランチ（origin/main 決め打ちにしない） */
const resolveBaseRef = repoRoot => {
  const detected = parseDefaultBranch(
    git(['symbolic-ref', 'refs/remotes/origin/HEAD'], repoRoot),
  )
  const candidates = detected ? [detected, 'main', 'master'] : ['main', 'master']
  for (const name of candidates) {
    if (git(['show-ref', '--verify', `refs/remotes/origin/${name}`], repoRoot)) {
      return `origin/${name}`
    }
  }
  return 'origin/main'
}

// du は node_modules を丸ごと stat して回るので、worktree 1 個で数秒かかる。
// サイズは表示にしか使わず判定には関与しないため、既定では測らない。
const directorySizeKb = path => {
  try {
    const out = execFileSync('du', ['-sk', path], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    })
    return Number.parseInt(out.split(/\s+/)[0], 10) || 0
  } catch {
    return 0
  }
}

/** ブランチに紐づく PR を GitHub に問い合わせる。無ければ null */
const fetchPr = branch => {
  if (!branch) {
    return null
  }
  let raw = ''
  try {
    raw = execFileSync(
      'gh',
      [
        'pr',
        'list',
        '--head',
        branch,
        '--state',
        'all',
        '--limit',
        '1',
        '--json',
        'number,state,updatedAt,mergedAt,closedAt',
      ],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] },
    )
  } catch {
    return null
  }
  const list = JSON.parse(raw || '[]')
  if (list.length === 0) {
    return null
  }
  const pr = list[0]
  const stamp =
    pr.state === 'OPEN'
      ? pr.updatedAt
      : pr.mergedAt || pr.closedAt || pr.updatedAt
  return {
    number: pr.number,
    state: pr.state,
    ageDays: daysSince(stamp),
    updatedAt: pr.updatedAt,
  }
}

/**
 * worktree の管理ファイルが最後に触られた時刻を管理ディレクトリから読む。
 *
 * gitdir は `git worktree add` で作られ、HEAD はチェックアウトやコミットで更新される。
 * index は含めない。`git status` が stat 情報を書き戻すため、このツールで様子を
 * 見るだけで mtime が「今」になり、放置された worktree が現役に化けてしまう。
 */
export const readWorktreeTouchedAt = adminDir => {
  if (!adminDir) {
    return null
  }
  const stamps = ['gitdir', 'HEAD']
    .map(name => {
      try {
        return statSync(join(adminDir, name)).mtimeMs
      } catch {
        return null
      }
    })
    .filter(value => value !== null)
  return stamps.length === 0
    ? null
    : new Date(Math.max(...stamps)).toISOString()
}

const worktreeTouchedAt = worktreePath =>
  readWorktreeTouchedAt(git(['rev-parse', '--absolute-git-dir'], worktreePath))

/** 全 worktree の状態を集める。measureSize は既定 false（du が遅いため） */
export const collectWorktrees = (repoRoot, { measureSize = false } = {}) => {
  const commonDir = git(
    ['rev-parse', '--path-format=absolute', '--git-common-dir'],
    repoRoot,
  )
  const mainPath = commonDir.replace(/\/\.git$/, '')
  const baseRef = resolveBaseRef(repoRoot)

  return parseWorktreeList(
    git(['worktree', 'list', '--porcelain'], repoRoot),
  ).map(entry => {
    // git status は index を書き戻すことがあり mtime が今になってしまうため、
    // 「最後に触られた時刻」は status より先に読む
    const touchedIso = worktreeTouchedAt(entry.path)
    const status = git(['status', '--porcelain'], entry.path)
    const lines = status ? status.split(/\r?\n/) : []
    const ref = entry.branch || 'HEAD'
    const pr = fetchPr(entry.branch)
    const lastActivityDays = resolveLastActivityDays({
      lastCommitIso: git(['log', '-1', '--format=%cI'], entry.path) || null,
      prUpdatedAtIso: pr ? pr.updatedAt : null,
      worktreeTouchedIso: touchedIso,
    })

    return {
      path: entry.path,
      branch: entry.branch,
      isMain: entry.path === mainPath,
      isLocked: entry.isLocked,
      dirtyCount: lines.filter(l => l && !l.startsWith('?? ')).length,
      untrackedCount: lines.filter(l => l.startsWith('?? ')).length,
      aheadOfMain:
        Number.parseInt(
          git(['rev-list', '--count', `${baseRef}..${ref}`], entry.path),
          10,
        ) || 0,
      hasRemoteBranch:
        entry.branch !== null &&
        git(
          ['show-ref', '--verify', `refs/remotes/origin/${entry.branch}`],
          repoRoot,
        ) !== '',
      lastActivityDays,
      sizeKb: measureSize ? directorySizeKb(entry.path) : null,
      pr,
    }
  })
}

/** worktree 配下の node_modules を消す（木そのものは残す） */
const removeNodeModules = (root, depth = 0) => {
  if (depth > 4 || !existsSync(root)) {
    return 0
  }
  let removed = 0
  for (const name of readdirSync(root)) {
    const path = join(root, name)
    let isDir = false
    try {
      isDir = statSync(path).isDirectory()
    } catch {
      continue
    }
    if (!isDir) {
      continue
    }
    if (name === 'node_modules') {
      rmSync(path, { recursive: true, force: true })
      removed += 1
    } else if (name !== '.git') {
      removed += removeNodeModules(path, depth + 1)
    }
  }
  return removed
}

const applyVerdict = (row, repoRoot) => {
  if (row.verdict === 'slim') {
    const n = removeNodeModules(row.path)
    return `node_modules ${n} 個を削除`
  }
  if (row.verdict !== 'delete') {
    return 'なし'
  }
  // --force は使わない。git 自身が「汚れていたら消さない」を守ってくれる
  try {
    execFileSync('git', ['worktree', 'remove', row.path], {
      cwd: repoRoot,
      stdio: ['ignore', 'ignore', 'pipe'],
    })
  } catch (error) {
    return `worktree 削除に失敗: ${String(error.stderr || error.message).trim()}`
  }
  if (row.deleteBranch && row.branch) {
    try {
      execFileSync('git', ['branch', '-D', row.branch], {
        cwd: repoRoot,
        stdio: ['ignore', 'ignore', 'pipe'],
      })
      return `worktree とブランチ ${row.branch} を削除`
    } catch {
      return 'worktree を削除（ブランチ削除は失敗）'
    }
  }
  return 'worktree を削除'
}

const NUMERIC_FLAGS = {
  '--merged-grace': 'mergedGraceDays',
  '--stale-open': 'staleOpenDays',
  '--empty-grace': 'emptyGraceDays',
}

export const parseArgs = argv => {
  const options = { ...DEFAULTS, apply: false, json: false, size: false }
  let skipNext = false
  argv.forEach((arg, index) => {
    if (skipNext) {
      skipNext = false
      return
    }
    if (arg === '--apply') {
      options.apply = true
    } else if (arg === '--json') {
      options.json = true
    } else if (arg === '--size') {
      options.size = true
    } else if (NUMERIC_FLAGS[arg]) {
      const value = Number.parseInt(argv[index + 1], 10)
      if (Number.isNaN(value)) {
        throw new Error(`${arg} には日数を指定してください`)
      }
      options[NUMERIC_FLAGS[arg]] = value
      skipNext = true
    }
  })
  return options
}

const MARKS = {
  hold: '⚠ 要確認',
  keep: '  保持  ',
  slim: '  軽量化',
  delete: '→ 削除 ',
}
const ORDER = { hold: 0, keep: 1, slim: 2, delete: 3 }

const main = () => {
  const options = parseArgs(process.argv.slice(2))
  const repoRoot = git(['rev-parse', '--show-toplevel'], process.cwd())
  if (!repoRoot) {
    console.error('git リポジトリの中で実行してください')
    process.exitCode = 1
    return
  }

  const rows = collectWorktrees(repoRoot, { measureSize: options.size })
    .map(wt => ({ ...wt, ...classifyWorktree(wt, options) }))
    .sort(
      (a, b) =>
        ORDER[a.verdict] - ORDER[b.verdict] || (b.sizeKb ?? 0) - (a.sizeKb ?? 0),
    )

  if (options.apply) {
    for (const row of rows) {
      if (row.verdict === 'delete' || row.verdict === 'slim') {
        row.result = applyVerdict(row, repoRoot)
      }
    }
    git(['worktree', 'prune'], repoRoot)
  }

  if (options.json) {
    console.log(JSON.stringify({ rows, summary: summarize(rows) }, null, 2))
    return
  }

  console.log(
    options.apply
      ? '=== worktree GC（実行） ==='
      : '=== worktree GC（dry-run / 何も消しません） ===',
  )
  for (const row of rows) {
    const name = row.path.split('/').pop().slice(0, 34).padEnd(34)
    const size =
      row.sizeKb === null
        ? ''
        : ` ${(row.sizeKb / 1024 / 1024).toFixed(1).padStart(5)}GB`
    console.log(`${MARKS[row.verdict]} ${name}${size}  ${row.reason}`)
    if (row.result) {
      console.log(`${' '.repeat(9)}└─ ${row.result}`)
    }
  }

  const { counts, freedGb } = summarize(rows)
  console.log(
    `\n削除 ${counts.delete} / 軽量化 ${counts.slim} / 保持 ${counts.keep} / 要確認 ${counts.hold}`,
  )
  if (options.size) {
    console.log(
      `${options.apply ? '解放' : '解放見込み'}: 約 ${freedGb.toFixed(1)} GB`,
    )
  } else {
    console.log('サイズ未計測（--size を付けると計測します。数十秒かかります）')
  }
  if (!options.apply && counts.delete + counts.slim > 0) {
    console.log('\n実行するには --apply を付けてください。')
  }
}

// テストランナー経由で読み込まれたときは実行しない（NODE_TEST_CONTEXT は node --test が設定する）
if (
  !process.env.NODE_TEST_CONTEXT &&
  process.argv[1]?.endsWith('worktree-gc.mjs')
) {
  main()
}
