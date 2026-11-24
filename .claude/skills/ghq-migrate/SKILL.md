---
name: ghq-migrate
description: ghq 管理外に置いたローカル git リポジトリを ghq のレイアウト (<ghq root>/<host>/<path>) へ移す。worktree・Claude Code のメモリ/セッション履歴/プロンプト履歴/プロジェクト設定・mise trust も一緒に移す。「ghq 管理にしたい」「ghq に移したい」と言われたとき、または移行直後の新しいパスのセッションで事後処理をするときに使う。引数にリポジトリのパスを渡す (省略時はカレントのリポジトリ)。
---

# ghq-migrate

ローカルのリポジトリを `mv` で ghq のレイアウトへ移し、パスに紐づく周辺の状態を付け替える。

`ghq get` で clone し直す方式は採らない。gitignore されたファイル (`.env` 等)・ローカルブランチ・stash・worktree・Claude Code のメモリが失われるため。

## スクリプト

`~/.claude/skills/ghq-migrate/scripts/ghq-migrate.sh [--apply [--yes]] [--remote NAME] [--keep-worktrees] <repo>`

- フラグなしは dry-run。計画・注意・ブロッカーを表示するだけで何も変更しない
- 移行先は remote (既定 origin) の URL から `$(ghq root)/<host>/<path>` を導く
- リポジトリ外の worktree は既定で `<repo>/.claude/worktrees/<名前>` へ移す (名前はディレクトリ名から `<リポジトリ名>-` を除いたもの)。`--keep-worktrees` でその場に残してリンクだけ修復する
- 実体のない worktree (prunable) は対象外として注意に出す
- `--apply` で行うこと: リポジトリと worktree の移動 / `git worktree repair` / 必要なら `.git/info/exclude` に `/.claude/worktrees/` を追記 / `~/.claude/projects/<slug>` の改名 / `~/.claude/history.jsonl` の project パス書き換え / `~/.claude.json` の projects キーの付け替え / 旧パスが trust 済みだった場合の `mise trust`
- 書き換える前に history.jsonl と `~/.claude.json` を `*.bak-ghq-migrate-<日時>` へ退避する
- 旧 -> 新の対応表を `~/.local/state/ghq-migrate/<日時>-<名前>.tsv` に残す
- 行わないこと: 依存の再インストール / メモリ本文やシェル rc の書き換え (旧パスを含むファイルは一覧を出すだけ)
- ブロッカー: 移行先が既にある / 移動対象の中に cwd があるプロセス (Claude Code・dev サーバ・シェル) / worktree 名の衝突 / 移行先の Claude プロジェクトディレクトリが既にある

## フェーズの判定

`~/.local/state/ghq-migrate/*.tsv` の `repo` 行の移行先が現在のリポジトリのルートと一致する対応表があれば、移行は済んでいるので「事後処理」から始める。なければ「調査と準備」から始める。

## 調査と準備 (旧パスのセッション)

1. dry-run を実行する。このセッション自身の Claude Code や、リポジトリ内で動いている dev サーバがブロッカーに出るのは想定どおり
2. ユーザに次を要約して伝える
   - 移行先のパス
   - worktree の扱い。外部 worktree の未コミット変更 / 未 push は `git -C <wt> status --short` と `git -C <wt> log --oneline @{u}..` で確かめて報告する (移動するだけなので失われないが、不要な worktree を先に整理するか確認する)
   - ブロッカーの解消方法。Claude Code は対象のセッションをすべて終了する。dev サーバの止め方はプロジェクトの CLAUDE.md に従う。シェルはリポジトリの外へ `cd` する
   - 旧パスを参照しているファイルの一覧 (事後処理で直す)
3. 実行するコマンドをユーザに渡す。`--apply` は Claude Code から実行しない。セッションの cwd と、そのセッションが書き込んでいる `~/.claude/projects/<slug>` が実行中に動くため

```sh
cd ~ && ~/.claude/skills/ghq-migrate/scripts/ghq-migrate.sh --apply <旧パス>
cd <新パス> && claude   # 起動後に /ghq-migrate で事後処理
```

新しいパスで `claude` を起動するのは `--apply` の後にする。先に起動すると空のプロジェクトディレクトリが作られ、ブロッカーになる。

## 事後処理 (新パスのセッション)

1. 最新の対応表を読み、旧 -> 新の対応を把握する
2. `git worktree list` に prunable が増えていないこと、`git status` が移行前と変わらないことを確かめる
3. 絶対パスを焼き込む生成物を作り直す
   - lockfile を探し (ルートと、workspace 外の独立パッケージも)、lockfile を固定したままインストールする (`pnpm install --frozen-lockfile` / `npm ci` 等)。`node_modules/.bin` のシムが旧パスを含むため
   - git hooks (lefthook / husky 等) は hook ファイルに絶対パスを書くことがある。インストール時に再生成されるか (`prepare` スクリプト等) を確かめ、されなければ `lefthook install` 等を実行する
   - Python の venv はパスを焼き込むので作り直す (`uv sync` 等)
   - worktree の依存も同じく旧パスを含む。全部をいま入れ直すか、使うときに入れ直すかはユーザに確認する
4. プロジェクトの CLAUDE.md が定める検証 (完了の定義) を実行する
5. メモリのパス参照を更新する。このプロジェクトの `memory/` と、旧パスを含む他プロジェクトの memory が対象。対応表にある旧パス (絶対パスと `~/` 形式の両方) を新パスへ書き換える。対応表にない旧パス (既に存在しない worktree など、経緯として書かれたもの) は書き換えない。MEMORY.md の索引行も合わせる
6. メモリ以外で旧パスを参照しているもの (グローバル CLAUDE.md・skills・シェル rc・エディタのワークスペース) は修正案の提示にとどめる
7. ユーザに報告する
   - `~/.claude.json` のキーを付け替えなかった場合や、他のセッションに書き戻された場合は、初回起動で信頼ダイアログが 1 回出る
   - バックアップ (`*.bak-ghq-migrate-*`) は問題がなければ削除してよい
   - mise の trust 一覧には旧パスのリンク切れが残るが無害
