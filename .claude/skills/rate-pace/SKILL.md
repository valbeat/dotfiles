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
| `L0` | 余剰 < +7pt、または判定不能 | 現状維持。**何も変えない** |
| `L1` | 余剰 ≥ +7pt | 約半日ぶんの貯金。安いティアの底上げ |
| `L2` | 余剰 ≥ +14pt | 約1日ぶんの貯金。主戦力の格上げ・並列数増 |

余剰の判定は **7d のペース差のみ**で行う。5h は表示専用で判定に使わない。

### 各 tier で格上げする項目

この表が唯一の定義。モデル方針そのもの（Opus / Fable / Sonnet の使い分け、
セキュリティ監査に Fable を使わない）は `~/.claude/CLAUDE.md` にある。

| 対象 | `L0` | `L1` | `L2` |
|------|------|------|------|
| `/review` Step 2 Gather Context | haiku | sonnet | sonnet |
| `/review` Step 4 Confidence Scoring | haiku | sonnet | sonnet |
| `/review` Step 3 レビュアーのモデル | sonnet | sonnet | opus |
| `/review` Step 3 レビュアー体数 | 5 | 5 | 7 |
| `/review` Step 4.5 Fable 上限 | 1 | 3 | 5 |
| `/dev-workflow:spec` 設計レビュー（**予定・未実装**） | fable ×1 | fable ×1 | fable ×2（2体目は反証役） |
| Orca orchestration worker の既定モデル（`model:` 省略時のみ。**予定・未実装**） | sonnet | sonnet | opus |
| Orca orchestration 最大同時 worker（**予定・未実装**） | 3 | 4 | 6 |

「予定・未実装」の行は方針だけ先に決めたもので、tier を実際に読むのは現時点で `/review` だけ
（`/dev-workflow:spec` は `model: fable` 固定、orchestration スキルは tier を参照しない）。
実装するまで、これらの経路では tier に関係なく従来どおりの固定値で動く。

### ルール

- **fail closed**: 判定できないときは `L0`。エラーは握りつぶして従来どおり続行する
- **明示指定が最優先**: `--model` やタスクファイルの `model:` があれば tier は無視する
- **1実行につき1回だけ読む**: スキル起動時に tier を確定し、ステップごとに再取得しない（実行中に揺れて設定が混ざるのを防ぐ）
- **格上げは上の表に載っている項目だけ**。「余ってそうだから他も上げる」はしない
- **ユーザー確認は取らない。報告は1行のみ**:
  `Budget tier: L1 (+18.3pt) — Step 2/4 を sonnet、Fable 上限 3`
- **絶対上限**: どの tier でも Fable は1回の実行で最大5エージェント、orchestration の同時 worker は最大6、`/review` のレビュアーは最大7
- **ループ内実行は L1 が上限**: `/review --brief`（`/dev-workflow:impl` から反復呼び出しされる）のような経路では L2 に上げない
- **格上げ対象外**: セキュリティ系（Fable 禁止。`~/.claude/CLAUDE.md` 参照）、`suite-eval`（モデル指定が測定の独立変数のため自動格上げすると計測が壊れる）
- 格上げは自己制動する。消費すれば余剰が減り、次回の起動で自動的に降格する

閾値は `RATE_PACE_L1_X10` / `RATE_PACE_L2_X10`（0.1pt 単位の整数、既定 70 / 140）で上書きできる。

### 閾値が「1日ぶん」ではなく「半日ぶん」な理由

余剰は `elapsed - used` なので、上限は `100 - 週末の最終消費率` になる。
週を 85% で終える使い方なら余剰は最大 +15pt までしか伸びず、
**それより高い閾値は厳しいのではなく到達不能**になる。半日 / 1日 はそこから逆算した値。

### 週の前半で格上げされにくいのは仕様

経過率5%の時点では余剰の上限が +5pt なので、構造的に L1 に届かない。
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
