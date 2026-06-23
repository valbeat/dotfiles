# nix-darwin 段階導入 設計メモ

dotfiles に nix-darwin を段階導入するための設計メモ。いきなり全面 Nix 化はせず、
**最小構成（`.osx` の宣言化）から始めて、確認できたら Homebrew へ拡張**する方針。

## 背景・前提

- 対象は macOS のみ（NixOS は Linux 専用なので不採用。macOS 等価は nix-darwin + home-manager）
- このリポジトリの大半は頻繁に書き換わる AI ツール設定（`.claude/` `.codex/` `.gemini/`）であり、
  全面 Nix 化は学習コスト・運用相性の両面で重い
- 既存の配布方式（Makefile による symlink）は維持し、Nix が効く領域だけを切り出す
- 実機: `aarch64-darwin` / host `takumas-MacBook-Pro` / user `takuma`

## ゴール

- macOS のシステム設定（現状 `.osx` の手続き的 `defaults write`）を**宣言的・再現可能**にする
- `darwin-rebuild switch` 一発で適用でき、世代管理でロールバック可能にする
- 既存のシェル/エディタ設定や AI ツール設定には**一切触れない**

## スコープ

| 区分 | 対象 | 備考 |
|---|---|---|
| **Phase 1（最小）** | `flake.nix` ブートストラップ + `.osx` → `system.defaults` | ここから着手 |
| **Phase 2（次）** | Brewfile → `homebrew` モジュール | `make brew` を rebuild に統合 |
| **当面そのまま** | `.zshrc`(27KB) / `.vimrc` / `.tmux.conf` / `.config/*` | home-manager 化は移植コスト大。symlink 維持 |
| **対象外** | `.claude/` `.codex/` `.gemini/` | 頻繁に書き換わる。宣言化すると毎回 rebuild で不便 |

## 前提条件（Nix 本体の導入）

Phase 1 の前に Nix のインストールが必要（Determinate Systems インストーラ推奨。flakes が既定で有効）。
※ セッションからは実行できないため、プロンプトに `!` を付けて手動実行する。

```
! /bin/sh -c "$(curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix)" -- install
```

初回 nix-darwin ブートストラップ（flake を指定して switch）:

```
! nix run nix-darwin -- switch --flake ~/dotfiles#takumas-MacBook-Pro
```

2 回目以降は `darwin-rebuild switch --flake ~/dotfiles#takumas-MacBook-Pro`。

## ディレクトリ構造（提案）

最小構成では追加ファイルを 2〜3 個に留める。`.osx` は移行確認まで残す。

```
dotfiles/
├── flake.nix                  # 入口。nixpkgs / nix-darwin を pin し host を定義
├── flake.lock                 # nix が自動生成（pin の固定）
└── darwin/
    ├── configuration.nix      # トップレベル。モジュールを import
    ├── system-defaults.nix    # Phase 1: .osx 移植
    └── homebrew.nix           # Phase 2: Brewfile 移植（後日）
```

`flake.nix` の骨子（イメージ。実装は別途）:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nix-darwin }: {
    darwinConfigurations."takumas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./darwin/configuration.nix ];
    };
  };
}
```

## Phase 1: `.osx` → `system.defaults` 対応表

`.osx` の各 `defaults write` を nix-darwin オプションへ移植する。標準オプションが無いものは
汎用エスケープハッチ `system.defaults.CustomUserPreferences` を使う。
`killall Finder/Dock`（反映のための再起動）は **darwin-rebuild の activation が自動実行**するため不要。

| `.osx` の設定 | nix-darwin の宣言 | 備考 |
|---|---|---|
| `finder AppleShowAllFiles yes` | `system.defaults.finder.AppleShowAllFiles = true;` | 標準 |
| `finder _FXShowPosixPathInTitle yes` | `system.defaults.finder._FXShowPosixPathInTitle = true;` | 標準 |
| `finder QLEnableTextSelection yes` | `CustomUserPreferences."com.apple.finder".QLEnableTextSelection = true;` | 旧 QuickLook 設定。現行 macOS では効果薄の可能性 |
| `dock expose-animation-duration 0.15` | `system.defaults.dock.expose-animation-duration = 0.15;` | 標準 |
| `dock workspaces-swoosh-animation-off yes` | `CustomUserPreferences."com.apple.dock"."workspaces-swoosh-animation-off" = true;` | 非標準 |
| `dashboard mcx-disabled yes` | （移植せず削除を推奨） | Dashboard は現行 macOS で廃止済み・obsolete |
| `Dock showhidden yes` | `system.defaults.dock.showhidden = true;` | 標準 |
| `.GlobalPreferences com.apple.trackpad.scaling 10` | `CustomUserPreferences.".GlobalPreferences"."com.apple.trackpad.scaling" = 10.0;` | トラックパッド速度 |
| `desktopservices DSDontWriteNetworkStores true` | `CustomUserPreferences."com.apple.desktopservices".DSDontWriteNetworkStores = true;` | .DS_Store 抑制 |
| `-g NSNavPanelExpandedStateForSaveMode yes` | `system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;` | 標準 |
| `CrashReporter DialogType "none"` | `CustomUserPreferences."com.apple.CrashReporter".DialogType = "none";` | 非標準 |
| `-g InitialKeyRepeat 12` | `system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;` | 標準 |
| `-g KeyRepeat 1` | `system.defaults.NSGlobalDomain.KeyRepeat = 1;` | 標準 |
| `killall Finder` / `killall Dock` | （不要） | activation が自動で反映 |

移植時の判断:
- **`dashboard mcx-disabled`** は obsolete のため Phase 1 では移植せず、`.osx` 側からも将来削除候補
- `QLEnableTextSelection` / `workspaces-swoosh-animation-off` は効果が怪しいが、挙動を変えないため一旦そのまま移植

## Phase 2: Brewfile → `homebrew` モジュール（後日）

nix-darwin の `homebrew` モジュールは既存の Homebrew を宣言的に扱える。

- `homebrew.enable = true;` + `homebrew.taps/brews/casks` に Brewfile の内容を移植
- `homebrew.onActivation.cleanup = "zap";`（または `"uninstall"`）で**宣言外パッケージを自動削除** →
  今回手動でやった `brew uninstall` 相当が宣言で完結する
- `make brew` / `make brew-dump` は段階的に廃止し、`darwin-rebuild switch` に統合
- 注意: `openssl@1.1` のような「依存で必要だが明示したくない」ものの扱いは Phase 2 で再検討
  （cleanup を `"uninstall"` 以上にすると依存解決の挙動を要確認）

## 移行手順（Phase 1）

1. Nix をインストール（前提条件参照）
2. `flake.nix` + `darwin/configuration.nix` + `darwin/system-defaults.nix` を作成（`.osx` は残す）
3. `nix run nix-darwin -- switch --flake ~/dotfiles#takumas-MacBook-Pro` でブートストラップ
4. 設定が反映されたか確認（Finder の隠しファイル表示、キーリピート等）
5. 問題なければ `.osx` を `make` の対象から外す → 動作確認後に `.osx` を削除
6. すべてフィーチャーブランチ + PR で実施（main 直 push しない）

## ロールバック

- `darwin-rebuild switch` は世代（generation）を作るため、`darwin-rebuild --rollback` で前世代に戻せる
- `.osx` を移行確認まで残すので、最悪 Nix を外して従来運用へ復帰可能
- `defaults write` は元の値を破壊的に上書きするため、不安なら移行前に
  `defaults read` で現行値を控えておく

## 当面やらないこと（明示）

- **home-manager 導入**: `.zshrc` 等の dotfile 管理を Nix へ寄せるのは移植コストが大きく、
  symlink 方式の即時反映性を失うため Phase 3 以降の検討事項
- **CLI パッケージの nixpkgs 化**: Homebrew と二重管理になりやすい。Phase 2 の Homebrew 統合を優先
- **AI ツール設定の Nix 化**: 対象外（前述）

## 未決事項

- nixpkgs を `unstable` で追うか、安定版（例 `nixpkgs-24.11`）に pin するか
- ホスト/ユーザー名のパラメータ化（将来マシンが増えた場合の `mkDarwin` 関数化）
- Phase 2 で Homebrew cleanup をどこまで強める（`uninstall` / `zap`）か
- `.osx` を最終的に削除するか、Nix 非導入環境向けに残すか
