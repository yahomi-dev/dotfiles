### セットアップ手順

1. ```git clone...```
2. ```cd dotfiles```
3. ```ghq get https://github.com/yahomi-dev/coding-style.git``` (Claude Code の rules と skills の一部が coding-style への symlink のため)
4. ```bash install.sh```

node等のランタイム管理はmise（Brewfileでインストール）。Claude Code本体はネイティブインストーラ（`curl -fsSL https://claude.ai/install.sh | bash`）。

### Claude Code の設定

- `.claude/` -> `~/.claude/` (通常のプロファイル)。CLAUDE.md、settings.json、rules、skills、hooks、scripts、statusline を symlink する
- `.claude-work/` -> `~/.claude-work/` (仕事用のプロファイル。`.zshrc` の `work-claude` で `CLAUDE_CONFIG_DIR=~/.claude-work` として起動する)。CLAUDE.md と rules は通常のプロファイルと共通
- 既に実体のあるファイルやディレクトリは上書きせずに `SKIP` と表示する。中身を確認して退避してから再実行する
- 管理しないもの: 認証情報、履歴、セッション、`~/.claude.json`、プロジェクトのメモリ、claude.ai から同期されるスキル (`skills/synced/`)、外部から取得したスキル
- 社内名を含むスキルは別のリポジトリ (dot-claude-work) で管理する。`~/dev/dot-claude-work` に clone してあれば (場所は `WORK_SKILLS_DIR` で変更可)、setup が `~/.claude/skills/` に symlink する
- MCP は context7 だけを setup で追加する。認証が要るサーバは各サービスの手順で追加する
