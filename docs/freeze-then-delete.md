# Freeze-then-Delete プロセス

> **安全なファイル削除のための 3 段階プロセス**
>
> 誤削除を防ぎつつ、リポジトリのクリーンさを維持するための仕組み。

---

## 概要

Freeze-then-Delete は、不要になったファイルを安全に削除するための 3 段階プロセスです。

| 段階 | 名称 | 説明 |
|------|------|------|
| 1 | **Freeze** | ファイルを FREEZE_QUEUE に追加し、一定期間保持 |
| 2 | **Confirm** | 凍結期間中に削除が適切か確認 |
| 3 | **Delete** | 凍結期間経過後、ファイルを削除し DELETE_LOG に記録 |

### なぜ必要か

- **誤削除の防止**: 即時削除ではなく、一定期間の猶予を設ける
- **履歴の保持**: 削除したファイルの記録を DELETE_LOG に残す
- **復旧の可能性**: 凍結期間中であれば、削除をキャンセルできる
- **監査証跡**: いつ、なぜファイルが削除されたかを追跡可能

---

## プロセスフロー

```
   +-----------------+
   |  不要ファイル   |
   |   を特定       |
   +--------+--------+
            |
            v
   +-----------------+
   |  freeze-file.sh |  Stage 1: FREEZE
   |  でキューに追加 |
   +--------+--------+
            |
            v
   +-----------------+
   |  凍結期間       |  Stage 2: CONFIRM
   |  (デフォルト7日)|  この間に削除を確認/キャンセル可能
   +--------+--------+
            |
            v
   +-----------------+
   | delete-frozen.sh|  Stage 3: DELETE
   |  で削除実行     |
   +--------+--------+
            |
            v
   +-----------------+
   |  DELETE_LOG に  |
   |  記録           |
   +-----------------+
```

---

## 使用方法

### Stage 1: ファイルを凍結キューに追加

```bash
# 基本的な使い方
bash scripts/freeze-file.sh <file_path>

# 理由を指定
bash scripts/freeze-file.sh old-script.sh --reason "replaced by new-script.sh"

# dry-run で確認
bash scripts/freeze-file.sh deprecated.md --dry-run
```

**オプション:**

| オプション | 説明 |
|-----------|------|
| `--reason "理由"` | 凍結理由を指定（デフォルト: "deprecated"） |
| `--dry-run` | 実際の変更なしで動作確認 |
| `--help` | ヘルプを表示 |

### Stage 2: 凍結期間中の確認

凍結されたファイルは state.md の FREEZE_QUEUE セクションで確認できます:

```yaml
## FREEZE_QUEUE

queue:
  - { path: "old-script.sh", freeze_date: "2025-12-19", reason: "replaced by new-script.sh" }
freeze_period_days: 7
```

**削除をキャンセルする場合:**

state.md の FREEZE_QUEUE から該当エントリを手動で削除してください。

### Stage 3: 凍結期間経過後の削除

```bash
# dry-run で削除対象を確認
bash scripts/delete-frozen.sh --dry-run

# 実際に削除を実行
bash scripts/delete-frozen.sh

# 凍結期間を変更して実行（例: 14日）
bash scripts/delete-frozen.sh --days 14
```

**オプション:**

| オプション | 説明 |
|-----------|------|
| `--days N` | 凍結期間を指定（デフォルト: state.md の freeze_period_days、なければ 7） |
| `--dry-run` | 実際の削除なしで動作確認 |
| `--help` | ヘルプを表示 |

---

## state.md のセクション

### FREEZE_QUEUE

削除予定ファイルの凍結キュー:

```yaml
## FREEZE_QUEUE

queue:
  - { path: "path/to/file", freeze_date: "YYYY-MM-DD", reason: "理由" }
freeze_period_days: 7
```

| フィールド | 説明 |
|-----------|------|
| `path` | 削除対象ファイルのパス |
| `freeze_date` | 凍結開始日 |
| `reason` | 凍結理由 |
| `freeze_period_days` | 凍結期間（日数） |

### DELETE_LOG

削除されたファイルの履歴:

```yaml
## DELETE_LOG

log:
  - { path: "path/to/file", deleted_date: "YYYY-MM-DD", reason: "理由" }
```

| フィールド | 説明 |
|-----------|------|
| `path` | 削除されたファイルのパス |
| `deleted_date` | 削除実行日 |
| `reason` | 削除理由（凍結時の理由を継承） |

---

## ベストプラクティス

1. **即時削除は避ける**: 不要なファイルは直接削除せず、まず凍結キューに追加
2. **理由を明記する**: 後から見ても理解できる理由を `--reason` で指定
3. **定期的に確認**: `delete-frozen.sh --dry-run` で削除対象を定期確認
4. **履歴を保持**: DELETE_LOG は削除せず、監査証跡として保持

---

## トラブルシューティング

### Q: 凍結をキャンセルしたい

state.md の FREEZE_QUEUE から該当エントリを手動で削除してください。

### Q: 凍結期間を変更したい

state.md の `freeze_period_days` を編集するか、`--days` オプションで一時的に上書きしてください。

### Q: 削除したファイルを復元したい

DELETE_LOG には削除の記録のみが残ります。ファイル自体の復元が必要な場合は、git の履歴から復元してください:

```bash
git checkout HEAD~N -- path/to/deleted/file
```

---

## 関連ドキュメント

| ファイル | 説明 |
|----------|------|
| `state.md` | FREEZE_QUEUE と DELETE_LOG のセクション |
| `scripts/freeze-file.sh` | 凍結キュー追加スクリプト |
| `scripts/delete-frozen.sh` | 削除実行スクリプト |
| `docs/folder-management.md` | フォルダ管理ルール |
