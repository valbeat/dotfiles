---
name: rate-pace
description: >-
  7d レート制限の消費ペースから budget tier (L0/L1/L2) を判定する。
  スキルが「余っている枠をモデル格上げに回してよいか」を決めるための共通部品。
  Use when a skill needs to decide whether to upgrade models or increase
  parallelism based on remaining weekly rate limit budget.
---

# Rate Pace — Budget Tier

## 何を答えるか

「今週のレート制限の消費ペースに対して**先行しているか**」の一点だけを答える。
残量そのものではなく **ペース差**で見る。

```
elapsed = (1 - (resets_at - now) / 604800) × 100     経過率
pace    = elapsed - used                             余剰pt
```

経過率60%・消費35% → **+25pt の貯金**。7d 枠は繰り越されないので、週内に使わなければ消える。
経過率30%・消費55% → **-25pt の先食い**。5h 枠が空いていても格上げしてはいけない。

単純な残量%で判定すると週初が常に「余っている」と誤判定され、先食いを招く。

## 使い方

```bash
bash ~/.claude/skills/rate-pace/scripts/pace.sh tier
# -> L0 | L1 | L2   （1語のみ）

bash ~/.claude/skills/rate-pace/scripts/pace.sh
# -> tier=L1 pace=+15.2 used=74.0 elapsed=89.2 left=26.0 age=4 conf=medium reason=ok
```

**常に exit 0 を返す。** `set -e` 配下から呼んでも落ちない。判定結果は `tier=` に載る。

## tier

7d の1日ぶん = 100 / 7 = **14.29pt**。これを単位にしている。

| tier | 条件 | 意味 |
|------|------|------|
| `L0` | 余剰 < +15pt、または判定不能 | 現状維持。**何も変えない** |
| `L1` | 余剰 ≥ +15pt | 約1日ぶんの貯金。安いティアの底上げ |
| `L2` | 余剰 ≥ +30pt | 約2日ぶんの貯金。主戦力の格上げ・並列数増 |

各 tier で具体的に何を格上げするかは `~/.claude/CLAUDE.md` の
**Model Selection Policy → Budget Tier** の表が唯一の定義。ここには書かない。

閾値は `RATE_PACE_L1_X10` / `RATE_PACE_L2_X10`（0.1pt 単位の整数、既定 150 / 300）で上書きできる。

### 週の前半で格上げされないのは仕様

経過率10%の時点では余剰の上限が +10pt なので、構造的に L1 に届かない。
「予算を使っていない」と「使ってよい貯金がある」は別物で、序盤に格上げを解禁すると
2日で週予算を焼く。

なお `pace ≤ left` は恒等的に成り立つ（`elapsed ≤ 100` のため）。
L1 を超えた時点で最低でも同じだけの枠が残っていることが保証されるので、
残量の下限チェックは別途持たない。

## 判定不能時は必ず現状維持

`reason` が `ok` 以外のときは `L0` を返す。**格上げしない**という意味であって、
処理を止めるという意味ではない。呼び出し側はそのまま従来どおり続行する。

| reason | 状況 |
|--------|------|
| `nocache` | キャッシュ未生成（statusline がまだ描画されていない） |
| `stale` | 30分以上更新されていない |
| `soft_stale` | 5分以上経過。値は返すが**格上げは禁止** |
| `schema` / `malformed` | キャッシュ形式が想定外 |
| `no_rate_limits` | `rate_limits` が届いていない |
| `window_longer` / `window_mismatch` / `window_rolling` | 7日固定窓の前提が崩れている（後述） |

### stale の扱いが非対称な理由

`used` は単調増加するので、キャッシュが古いと `used` は必ず**過小評価**され、
結果として余剰は必ず**過大評価**される。古いデータでの格上げは構造的に危険側、
格下げは安全側。そのため 5分〜30分は「値は返すが格上げ禁止」、30分超は `unknown` にする。

5分という閾値が実用上きつくない理由: このスクリプトを呼ぶのは生きた Claude セッションの
中で、そのセッションの statusline が数百ms毎に回っている。**「読める＝新鮮」が構造的に成り立つ。**

## データの出どころ

```
statusLine stdin JSON  ← Claude Code が rate_limits を渡す唯一の経路
  └─ ~/.claude/statusline.sh          （書き手・15秒 throttle・atomic rename）
       └─ ~/.claude/cache/rate-pace.tsv   （1行 TSV・git 管理外）
            └─ scripts/pace.sh            （読み手・判定）
```

**statusline.sh に依存している。** `settings.json` の `statusLine` を無効化したり
別実装に差し替えたりすると、このスキルは恒久的に `nocache` を返す（＝全て L0 になり、
挙動は従来どおりに戻る）。

`claude` CLI に使用量を取るサブコマンドは無く、一次ソースの `GET /api/oauth/usage` は
OAuth トークンが Keychain 保管のため自前では叩けない。`ccusage` 等の外部ツールが出すのは
transcript からのローカル推定であって公式の使用率ではないため、フォールバックには**使わない**。
誤判定で枠を焼くより、現状維持のほうが安い。

## 7日固定窓の前提を実測で検証している

ペースの計算は「7d 枠が固定7日窓で、リセット時に丸ごと戻る」ことを前提にしている。
もしローリング窓だった場合 `remaining` はほぼ一定になり、経過率は無意味になる。

書き手が O(1) の状態を持ち回って検出する。

- `max_remaining` — 観測した `remaining` の最大値。固定窓なら真の窓長に下から収束する
- `window_measured` — ロールオーバー検出時の `resets_at` の差分（窓長の直接観測）
- `anchor_at` / `anchor_remaining` — ドリフト測定の基準点

読み手はこれらから、窓が想定より長い / 実測値が5%以上ずれている /
`remaining` が実時間どおりに減っていない、のいずれかを検出したら `unknown` を返す。
**前提が崩れた瞬間に格上げが止まる**のが正しい壊れ方。

## キャッシュの形式

1行 TSV。第1フィールドが schema version。

```
schema  updated_at  used_x10  resets_at  remaining  max_remaining  anchor_at  anchor_remaining  window_measured  five_used_x10  five_resets_at
```

全ての百分率は **0.1% 単位の整数**（`used_x10=740` は 74.0%）。bash 算術に浮動小数を
持ち込まないため。将来フィールドを追加するときは schema を上げること。
古い読み手は `schema` 不一致で `unknown`＝安全側に落ちる。
