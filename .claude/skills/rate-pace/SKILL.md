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
# -> tier=L1 pace=+18.3 used=31.2 elapsed=49.5 left=68.8 reason=ok
```

**常に exit 0 を返す。** `set -e` 配下から呼んでも落ちない。判定結果は `tier=` に載る。

1回あたり **0.4〜0.6秒**（ネットワーク往復）。スキルは**起動時に1回だけ**呼び、
ステップごとに呼び直さないこと。

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

## データの出どころ

Claude Code 本体が使うのと同じエンドポイントを直接叩く。

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <Keychain の "Claude Code-credentials" の accessToken>
```

`.seven_day.utilization`（パーセント値）と `.seven_day.resets_at`（ISO 8601, UTC）だけを使う。

- **statusLine には依存しない。** statusLine は Claude Code が同じ API を叩いた結果を
  受け取って表示しているだけで、API そのものではない
- トークンは `curl --config -` で**標準入力から**渡す。コマンドライン引数に置くと
  `ps` で他プロセスから読めてしまうため
- タイムスタンプの変換は jq の `fromdateiso8601` で行う。`date -d` / `date -j` の
  GNU / BSD 差を踏まないため。**UTC 以外のオフセットは受け付けない**
  （経過率が静かにずれるより、判定不能にするほうが安全）

## 判定不能時は必ず現状維持

`reason` が `ok` 以外のときは `L0` を返す。**格上げしない**という意味であって、
処理を止めるという意味ではない。呼び出し側はそのまま従来どおり続行する。

| reason | 状況 |
|--------|------|
| `notoken` | Keychain からトークンを取得できない（SSH でロック中、ログアウト済み等） |
| `fetch_failed` | ネットワーク不通、タイムアウト（5秒）、**401 を含む HTTP エラー** |
| `unparseable` | レスポンスの形が想定外、または `resets_at` が UTC でない |
| `window_longer` | 1週間より長い残り時間が返ってきた（7日固定窓の前提が崩れている） |
| `nojq` / `nokeychain` | 依存コマンドが無い |

### 401 は放置する

アクセストークンの寿命は約12時間で、Claude Code 本体が期限前に更新する。
更新前に叩けば 401 になるが、**このスクリプトは自前でリフレッシュしない**。
本体の認証状態を外から書き換えるほうが、格上げを1回見送るよりはるかに危険なため。
本体が更新すれば次回から自然に復旧する。

## 環境要件

| 要件 | 満たさない場合 |
|------|----------------|
| `security`（macOS Keychain）が読めること | `notoken` → `L0` |
| ネットワーク到達性 | `fetch_failed` → `L0` |
| `jq` 1.5 以上（`fromdateiso8601` を使う） | `nojq` → `L0` |
| `bash` 3.2 以上 | — （macOS 既定の 3.2 で動作確認済み） |

**SSH 越しやヘッドレスでは login keychain がロックされていて失敗する**ことがある。
その場合は全て `L0` になり、挙動は従来どおりに戻るだけ。

macOS 専用なのは Keychain 参照の1行のみ。Linux へ持っていく場合はここだけ差し替える。

**1つの環境を複数の Claude アカウントで使い分ける構成では、
`security` が返すトークン＝現在ログイン中のアカウントの値になる**点に注意。

## 7日固定窓という前提

`elapsed` の計算は「7d 枠が固定7日窓で、リセット時に丸ごと戻る」ことを前提にしている。
2026-08-02 に実際のロールオーバーを観測し、窓長が**ちょうど 604800 秒**であることを
実測で確認済み（推定ではない）。

前提が崩れた場合の壊れ方も安全側になっている。

- **窓が長くなった** … 残り時間が 604800 秒を超えるので `window_longer` で検出して `L0`
- **ローリング窓になった** … `remaining` が最大値付近に貼り付くため `elapsed` が常に ≈0 になり、
  `pace = 0 - used ≤ 0` で L1 に届かない。**ガードを書かなくても自動的に L0 に落ちる**
