---
name: daily-report
description: AIエージェントツール実証実験の作業日報をセッション内容から自動生成する。Stop hookで集約済みのトランスクリプトを元に、当日の日報を二段要約で生成する。
---

## 保存先ディレクトリの取得

最初に以下のコマンドを実行して保存先ディレクトリを取得してください:

```bash
REPORTS_DIR="${DAILY_REPORT_DIR:-$HOME/.claude-work/reports}"
echo "${REPORTS_DIR/#\~/$HOME}"
```

取得したパスを `REPORTS_DIR` として以降の処理で使用します。

---

## 前提

Stop hook (`~/.claude-work/hooks/backup-transcript.sh`) が毎ターンの会話JSONLを以下に集約しています:

```
$REPORTS_DIR/YYYY-MM-DD/transcripts/<sessionId>.jsonl
```

本スキルはそのファイル群を読み込んで日報を生成します。`/daily-report` の実行は1日の終わりに1回だけ行えばOKです。

---

## 手順

### フェーズ1: セッション要約の生成（キャッシュあり）

1. 今日の日付を取得する:
   ```bash
   date +%Y-%m-%d
   ```

2. `$REPORTS_DIR/YYYY-MM-DD/transcripts/` 内の JSONL ファイルを列挙する:
   ```bash
   ls "$REPORTS_DIR/YYYY-MM-DD/transcripts/"*.jsonl 2>/dev/null
   ```

3. 各 JSONL ファイルについて、対応する中間要約ファイル `$REPORTS_DIR/YYYY-MM-DD/session-<sessionId>.md` の存在と更新日時を確認する:
   ```bash
   ls -la "$REPORTS_DIR/YYYY-MM-DD/session-<sessionId>.md" 2>/dev/null
   ```

4. 中間要約が **未生成、または JSONL のほうが新しい** 場合は Read ツールで JSONL を読み込んでセッション要約を生成し `session-<sessionId>.md` として保存する:

   **JSONL パース時のルール:**
   - 除外する行: `"type":"permission-mode"`, `"type":"file-history-snapshot"`, `"type":"attachment"`
   - `user` エントリ: `message.content` のテキスト部分を抽出
   - `assistant` エントリ: `message.content[]` のうち `type:"text"` のテキストと `type:"tool_use"` の `name` のみ抽出（`type:"thinking"` は除外）
   - `timestamp` はセッションの開始・終了時刻として記録

   **中間要約フォーマット:**

```markdown
# セッション <sessionId 先頭8文字> (HH:MM〜HH:MM)

### 実施内容
- （会話から抽出した作業内容を箇条書き）

### 使用した主要なプロンプト・指示
- （効果的だった指示や改善が必要だった指示）

### 人間の判断が必要だった箇所
- （AIが自律的に解決できなかった判断ポイント）
```

### フェーズ2: 日報統合

5. 当日の全 `session-*.md` ファイルを Read ツールで読み込む:
   ```bash
   ls "$REPORTS_DIR/YYYY-MM-DD/session-"*.md 2>/dev/null
   ```

6. 読み込んだ全セッション要約を統合して、以下のフォーマットで日報を生成する

7. 生成した日報を `$REPORTS_DIR/YYYY-MM-DD/daily-report-YYYY-MM-DD.md` に**上書き保存**する（画面には出力しない）

8. 保存先ファイルパスをユーザーに伝える

---

## 日報フォーマット

```markdown
# 【作業日報】AIエージェントツール実証実験

**日付:** YYYY年MM月DD日

### 1. 実施タスク概要

その日の全セッションを通じて実施したコード修正・機能追加・調査の内容を具体的に箇条書きで記述してください。

### 2. 使用した主要なプロンプト

効果的だったプロンプト・指示、または改善が必要だったプロンプトを具体的に記述してください。

### 3. 実行プロセスと推移

作業の進め方（例：計画 → 実装 → テスト → 修正）を時系列で記述してください。

### 4. 効率化の定量・定性評価

- **手動対比の工数:** （例：手動 30 分 → AI で 10 分）
- **AIが自律的に解決できた範囲:**
- **人間の判断が必要だった箇所:**

### 5. 課題と気付き

- **つまずいた点:**
- **次回のプロンプト改善案:**
- **ツール・ワークフローの改善提案:**
```
