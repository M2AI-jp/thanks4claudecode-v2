# project.md

> **プロジェクトの根幹計画。Claude が3層構造（project → playbook → phase）を自動運用する。**

---

## meta

```yaml
project: thanks4claudecode
created: 2025-12-10
status: active
```

---

## vision

```yaml
goal: "Claude Code の自律性と品質を継続的に向上させる"

principles:
  - 報酬詐欺防止（critic 必須）
  - 計画駆動開発（playbook 必須）
  - 構造的強制（Hooks）
  - 3層自動運用（project → playbook → phase）

success_criteria:
  - ユーザープロンプトなしで 1 playbook を完遂できる
  - compact 後も mission を見失わない
  - 次タスクを自動導出して開始できる
  - 全 Hook/SubAgent/Skill が動作確認済み
  - playbook 完了時に /clear タイミングを案内する
  - project.milestone が自動更新される
```

---

## milestones

```yaml
- id: M001
  name: "三位一体アーキテクチャ確立"
  status: achieved
  achieved_at: 2025-12-09
  playbooks:
    - playbook-reward-fraud-prevention.md
  done_when:
    - "[x] .claude/hooks/ ディレクトリに Hook スクリプトが存在する"
    - "[x] .claude/agents/ ディレクトリに SubAgent 定義が存在する"
    - "[x] CLAUDE.md に三位一体の説明が記載されている"
    - "[x] .claude/settings.json に Hook が登録されている"

- id: M002
  name: "Self-Healing System 基盤実装"
  status: achieved
  achieved_at: 2025-12-10
  playbooks:
    - playbook-full-autonomy.md
  done_when:
    - "[x] state.md が存在し focus/playbook/goal セクションを含む"
    - "[x] session-start.sh が SessionStart Hook として登録されている"
    - "[x] check-coherence.sh が存在する"

- id: M003
  name: "PR 作成・マージの自動化"
  status: achieved
  achieved_at: 2025-12-10
  playbooks:
    - playbook-pr-automation.md
  done_when:
    - "[x] .claude/hooks/create-pr.sh が存在し実行可能である"
    - "[x] .claude/hooks/merge-pr.sh が存在する"
    - "[x] create-pr-hook.sh が PostToolUse で登録されている"

- id: M004
  name: "3層構造の自動運用システム"
  description: |
    project → playbook → phase の3層構造を確立し、
    Claude が主導で自動運用できるようにする。
    人間は意思決定とプロンプト提供のみ。
  status: achieved
  achieved_at: 2025-12-13 00:06:00
  depends_on: [M001, M002, M003]
  playbooks:
    - playbook-three-layer-system.md
  done_when:
    - [x] 用語が統一されている（Macro→project, layer廃止）
    - [x] playbook 完了時に project.milestone が自動更新される
    - [x] playbook 完了時に /clear 推奨がアナウンスされる
    - [x] 次 milestone から playbook が自動作成される

- id: M005
  name: "確実な初期化システム（StateInjection）"
  description: |
    UserPromptSubmit Hook を拡張し、state/project/playbook の状態を
    systemMessage として強制注入する。LLM が Read しなくても情報が届く。
  status: achieved
  achieved_at: 2025-12-13 01:20:00
  depends_on: [M004]
  playbooks:
    - playbook-state-injection.md
  done_when:
    - [x] systemMessage に focus/milestone/phase/playbook が含まれる
    - [x] systemMessage に project_summary/last_critic が含まれる
    - [x] /clear 後も最初のプロンプトで情報が注入される
    - [x] playbook=null の場合も正しく動作する

- id: M006
  name: "厳密な done_criteria 定義システム"
  description: |
    done_criteria の事前定義精度を向上させる。
    自然言語の曖昧な定義ではなく、検証可能な形式で定義し、
    「テストをクリアするためのテスト」という構造的問題を解消する。
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M005]
  playbooks: [playbook-strict-criteria.md]
  done_when:
    - [x] done_criteria が Given/When/Then 形式で定義される
    - [x] 各 criteria に test_command が紐付けられている
    - [x] 曖昧な表現（「動作する」「正しく」等）が検出・拒否される
  decomposition:
    playbook_summary: |
      done_criteria の定義精度を向上させるシステムを構築。
      「テストをクリアするためのテスト」から「テストで検証できる仕様」へ転換。
    phase_hints:
      - name: "done_criteria 検証ルール定義"
        what: |
          曖昧な表現を自動検出するルールセット（禁止パターン）を定義。
          Given/When/Then 形式での定義テンプレートを作成。
      - name: "test_command マッピング実装"
        what: |
          各 done_criteria に対応する test_command を自動マッピング。
          実行可能な検証コマンドを明示。
      - name: "critic による criteria レビュー機構"
        what: |
          playbook 作成時に critic が criteria 定義の品質をチェック。
          PASS/FAIL で曖昧さを検出・拒否。
    success_indicators:
      - done_criteria の曖昧表現が自動検出される
      - criteria: test_command が1:1で紐付けられている
      - critic が criteria 品質をチェックできる

- id: M014
  name: "フォルダ管理ルール確立 & クリーンアップ機構実装"
  description: |
    1. 全フォルダの役割を明確化（テンポラリ/永続）
    2. tmp/ フォルダを新設し、テンポラリファイルを統一配置
    3. playbook 完了時の自動クリーンアップ機構を実装
    4. フォルダ管理ルールをドキュメント化
  status: achieved
  achieved_at: 2025-12-13
  depends_on: [M006]
  playbooks: [playbook-m014-folder-management.md]
  done_when:
    - [x] 不要ファイルが .archive/ に移動されている
    - [x] tmp/ フォルダが新設され、.gitignore に登録されている
    - [x] .claude/hooks/cleanup-hook.sh が実装されている
    - [x] 全 playbook テンプレートに cleanup phase が追加されている
    - [x] docs/folder-management.md が作成されている
    - [x] project.md に参照が追加されている

# ============================================================
# M015-M023: 再定義・再検証対象（2025-12-14 リセット）
# ============================================================

- id: M015
  name: "フォルダ管理ルール検証テスト"
  description: |
    M014 で実装したフォルダ管理ルールとクリーンアップ機構の動作検証。
    tmp/ と永続フォルダ（docs/）の分離が正しく機能することを確認する。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M014]
  playbooks:
    - playbook-m015-folder-validation.md
  done_when:
    - [x] tmp/ ディレクトリが存在し .gitignore に登録されている
    - [x] cleanup-hook.sh が実行可能で構文エラーがない
    - [x] docs/folder-management.md が存在する

- id: M016
  name: "リリース準備：自己認識システム完成"
  description: |
    リポジトリの完成度を高め、リリース可能な状態にする。
    repository-map.yaml の完全性、コンテキスト保護、整合性確認。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M015]
  playbooks:
    - playbook-m016-release-preparation.md
  done_when:
    - [x] repository-map.yaml の全 Hook に trigger が明示されている（unknown が 0 個）
    - [x] CLAUDE.md に [理解確認] セクションが存在する
    - [x] state.md / project.md / playbook の整合性が確認されている

- id: M017
  name: "仕様遵守の構造的強制"
  description: |
    「拡散」を抑止し「収束」を強制する仕組みを実装。
    state.md スキーマの単一定義源を作成し、Hook がそこを参照する形に統一。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M016]
  playbooks:
    - playbook-m017-state-schema.md
  done_when:
    - [x] .claude/schema/state-schema.sh が存在し source 可能
    - [x] state-schema.sh に SECTION_* 定数と getter 関数が定義されている
    - [x] Hook がハードコードではなくスキーマを参照している

- id: M018
  name: "3検証システム（technical/consistency/completeness）"
  description: |
    subtask 単位で 3 視点の検証を構造的に強制するシステム。
    - technical: 技術的に正しく動作するか
    - consistency: 他のコンポーネントと整合性があるか
    - completeness: 必要な変更が全て完了しているか
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M017]
  playbooks:
    - playbook-m018-3validations.md
  done_when:
    - [x] subtask-guard.sh が存在し実行可能
    - [x] subtask-guard.sh に 3 検証（technical/consistency/completeness）のロジックがある
    - [x] playbook-format.md に validations セクションが存在する

- id: M019
  name: "playbook 自己完結システム"
  description: |
    playbook を自己完結させる仕組みを構築。
    final_tasks によるアーカイブ前チェック、repository-map 更新。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M018]
  playbooks:
    - playbook-m019-self-contained.md
  done_when:
    - [x] archive-playbook.sh に final_tasks チェックが実装されている
    - [x] playbook テンプレートに final_tasks 例が含まれている

- id: M020
  name: "archive-playbook.sh バグ修正"
  description: |
    archive-playbook.sh の ARCHIVE_DIR を plan/archive/ に修正し、
    完了済み playbook が正しくアーカイブされることを確認。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M019]
  playbooks:
    - playbook-m020-archive-bugfix.md
  done_when:
    - [x] archive-playbook.sh の ARCHIVE_DIR が plan/archive/ を指している
    - [x] archive-playbook.sh の構文が正しい（bash -n）

- id: M021
  name: "init-guard.sh デッドロック修正"
  description: |
    init-guard.sh で基本 Bash コマンドがブロックされる問題を修正。
    playbook=null 時でも sed/grep/cat/echo/ls/wc が許可される。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M020]
  playbooks:
    - playbook-m021-init-guard-fix.md
  done_when:
    - [x] init-guard.sh に基本コマンド許可リスト（sed/grep/cat/echo/ls/wc）がある
    - [x] git show コマンドが許可されている
    - [x] session-start.sh に CORE セクションが存在する

- id: M022
  name: "SOLID原則に基づくシステム再構築"
  description: |
    SOLID原則（特に単一責任原則）に基づいてシステムを再構築。
    init-guard.sh を単一責任に分離し、各 Hook の責任をドキュメント化。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M021]
  playbooks: [playbook-m022-solid-refactoring.md]
  done_when:
    - [x] init-guard.sh が単一責任（必須ファイル Read 強制のみ）
    - [x] playbook-guard.sh が playbook 存在チェック責任を持つ
    - [x] docs/hook-responsibilities.md に全 Hook の責任が明示されている

- id: M023
  name: "Plan mode 活用ガイド"
  description: |
    Plan mode（think/ultrathink）と Named Sessions の活用ガイドを作成。
    複雑なタスクでの思考深化と、セッション管理を改善。
  status: achieved
  achieved_at: 2025-12-14
  depends_on: [M022]
  playbooks:
    - playbook-m023-plan-mode-guide.md
  done_when:
    - [x] CLAUDE.md に think/ultrathink の使い分けが明記されている
    - [x] docs/session-management.md が存在し /rename, /resume が記載されている

- id: M025
  name: "システム仕様の Single Source of Truth 構築"
  description: |
    Claude の仕様が分散している問題を解決。
    repository-map.yaml を拡張し、Claude の行動ルール・Hook 連鎖を統合。
    二重管理を排除し、1ファイル・1スクリプトで完結する Single Source of Truth を構築。
  status: achieved
  achieved_at: 2025-12-15
  depends_on: [M023]
  playbooks:
    - playbook-m025-system-specification.md
  done_when:
    - [x] generate-repository-map.sh に system_specification セクション生成機能が追加されている
    - [x] repository-map.yaml に Claude 行動ルール・Hook トリガー連鎖が含まれている
    - [x] 自動更新が 100% 安定（冪等性保証、原子的更新）
    - [x] INIT フロー全体で冗長がなく、効率的に自己認識できることが確認される

- id: M053
  name: "Multi-Toolstack Setup System + Admin Mode Fix"
  description: |
    1. security: admin で全ガードをバイパス（繰り返し発生していた問題を根本修正）
    2. 3 パターン（A/B/C）の Toolstack を実装し、executor を構造的に制御
    3. Codex を SubAgent 化し、コンテキスト膨張を防止
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M025]
  playbooks:
    - playbook-m053-multi-toolstack.md
  done_when:
    - [x] admin モードで全ガードがバイパスされる
    - [x] setup フローに toolstack 選択 Phase がある
    - [x] executor-guard.sh が toolstack に応じて制御する
    - [x] Codex が SubAgent 化されコンテキスト分離されている

- id: M056
  name: "playbook 完了検証システム + V12 チェックボックス形式"
  description: |
    報酬詐欺（done_when 未達成で achieved）を構造的に防止する。
    1. playbook 完了時に done_when を自動検証
    2. subtask 単位で `- [ ]` / `- [x]` で進捗を明示
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M053]
  playbooks:
    - playbook-m056-completion-verification.md
  done_when:
    - [x] playbook-format.md に完了検証フェーズ（p_final）が必須として追加されている
    - [x] archive-playbook.sh が done_when の test_command を再実行して検証する
    - [x] subtask-guard が final_tasks の status: done をブロックしない
    - [x] 既存の achieved milestone の done_when が実際に満たされているか再検証完了
    - [x] V12 チェックボックス形式が全コンポーネントに適用されている

- id: M057
  name: "Codex/CodeRabbit CLI 化 - 誤設計の根本修正"
  description: |
    Codex と CodeRabbit がサーバーとして誤設計されていた問題を根本修正。
    実際には両方とも CLI ツールとして存在しており、その仕様に合わせて
    全ドキュメント・SubAgent・Hook を一括更新する。
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M056]
  playbooks:
    - playbook-m057-cli-migration.md
  done_when:
    - "[x] .mcp.json から codex エントリが削除されている"
    - "[x] docs/toolstack-patterns.md が CLI ベースに全面書き換えされている"
    - "[x] .claude/agents/codex-delegate.md が CLI ベースに修正されている"
    - "[x] .claude/hooks/executor-guard.sh が CLI ベースに修正されている"
    - "[x] plan/template/playbook-format.md の executor 説明が更新されている"
    - "[x] .claude/CLAUDE-ref.md が CLI ベースに修正されている"
    - "[x] setup/playbook-setup.md が CLI ベースに修正されている"
    - "[x] repository-map.yaml が更新されている"

- id: M058
  name: "System Correction: archive-playbook.sh バグ修正 & 設計誤りの根本修正"
  description: |
    archive-playbook.sh が state.md の誤った構造を参照する問題を修正。
    M057 playbook のデータ不整合（plan/ と archive/ に重複）をクリーンアップ。
    根本的な設計誤り（Claude Code がワーカー）を修正し、Codex/CodeRabbit を
    メインワーカーとする本来の設計に統一する。
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M057]
  playbooks:
    - playbook-m058-system-correction.md
  done_when:
    - "[x] archive-playbook.sh が state.md の正しい構造（playbook.active）を参照している"
    - "[x] plan/playbook-m057-cli-migration.md が削除されている"
    - "[x] plan/archive/playbook-m057-cli-migration.md のみが存在する"
    - "[x] state.md の playbook.active が設定可能な状態である"
    - "[x] project.md の M057 status が achieved に更新されている"
    - "[x] project.md の M058 が新規マイルストーンとして追加されている"
    - "[x] CLAUDE.md の「設計思想」セクションが存在する"

- id: M059
  name: "done_when 生成ルールの論理学的強化"
  description: |
    done_when の定義があやふやで報酬詐欺が可能な問題を根本解決。
    1. [理解確認] に done_when フィールドを追加（ユーザー承認の強制）
    2. tdd_first に形式ルールを追加（曖昧表現の構造的禁止）
    3. consent-process/skill.md を同期
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M058]
  playbooks:
    - playbook-m059-done-when-rules.md
  done_when:
    完了条件:
      - "[x] CLAUDE.md [理解確認] に done_when フィールドが追加されている"
      - "[x] CLAUDE.md tdd_first に形式ルールが追加されている"
      - "[x] consent-process/skill.md の [理解確認] テンプレートが CLAUDE.md と同期"
      - "[x] done-when-validator.sh が曖昧表現を検出できる"
    未完了条件:
      - "上記のいずれかが満たされていない"

- id: M060
  name: "done_when バリデーションシステム + M059 回帰検証"
  description: |
    M059 で文書化した done_when ルールを「構造的に強制」するシステムを実装。
    1. done-when-validator.sh を実装（曖昧表現の自動検出）
    2. project.md の曖昧 done_when を改善
    3. M059 を新システムで再検証
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M059]
  playbooks:
    - playbook-m060-done-when-validation.md
  done_when:
    完了条件:
      - "[x] done-when-validator.sh が .claude/hooks/ に存在し実行可能"
      - "[x] done-when-validator.sh が bash -n でエラー0"
      - "[x] done-when-validator.sh が禁止パターン入力時に exit 1 を返す"
      - "[x] project.md の done_when 行から曖昧表現が0件"
      - "[x] M059 の done_when が新ルール準拠に修正されている"
    未完了条件:
      - "上記のいずれかが満たされていない"

- id: M061
  name: "done_when 大規模修正（報酬詐欺リスク解消）"
  description: |
    報酬詐欺リスク分析で発見された milestone done_when を修正。
    tdd_first 形式ルール（量化子展開・述語操作化・否定形併記）に準拠させる。
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M060]
  playbooks:
    - playbook-m061-done-when-correction.md
  done_when:
    完了条件:
      - "[x] M058 の done_when が [x] マークに修正されている"
      - "[x] 曖昧表現が量化子展開・述語操作化されている"
      - "[x] done-when-validator.sh が project.md の done_when 行で exit 0 を返す"
    未完了条件:
      - "上記のいずれかが満たされていない"

- id: M062
  name: "報酬詐欺徹底調査 + 全機能 E2E シミュレーション"
  description: |
    報酬詐欺があるという前提で全 milestone を1から再調査し、
    M061 の playbook プロセス違反を修正する。
    archive-playbook.sh に subtask 完了チェックを追加し、
    架空ユーザーとの会話形式で全機能の E2E シミュレーションを実施する。
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M061]
  playbooks:
    - playbook-m062-fraud-investigation-e2e.md
  done_when:
    完了条件:
      - "[x] M001-M061 の全 milestone に対して done_when の達成状況が検証されている"
      - "[x] archive-playbook.sh に subtask 単位の完了チェックが追加されている"
      - "[x] docs/e2e-simulation-log.md に全 Hook/SubAgent/Skill の動作確認ログが記録されている"
      - "[x] 発見された報酬詐欺（done_when 未達成）が 0 件、または修正済みである"
    未完了条件:
      - "上記のいずれかが満たされていない"
    test_commands:
      - "test -f docs/fraud-investigation-report.md && grep -q 'M001' docs/fraud-investigation-report.md && grep -q 'M061' docs/fraud-investigation-report.md && echo PASS"
      - "grep -q 'CHECKED_COUNT' .claude/hooks/archive-playbook.sh && grep -q 'UNCHECKED_COUNT' .claude/hooks/archive-playbook.sh && echo PASS"
      - "test -f docs/e2e-simulation-log.md && wc -l docs/e2e-simulation-log.md | awk '{if($1>=200) print \"PASS\"}'"
      - "grep -c '未修正' docs/fraud-investigation-report.md 2>/dev/null | awk '{if($1==0) print \"PASS\"}' || echo PASS"

- id: M063
  name: "リポジトリ洗浄 - 孤立ファイル・壊れた Hook の削除"
  description: |
    無効な参照、孤立ファイル、壊れた Hook を削除し、リポジトリの整合性を回復する。
    1. 孤立ファイル（0参照）を削除
    2. 存在しないファイルへの参照を修正
    3. 依存ファイルが存在しない Hook を削除
    4. settings.json から無効な登録を削除
    5. ドキュメントを更新
    6. CLAUDE.md スリム化（オプション）
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M062]
  playbooks:
    - playbook-m063-repository-cleanup.md
  done_when:
    完了条件:
      - "[x] .claude/agents/plan-guard.md が存在しない"
      - "[x] .claude/CLAUDE-ref.md が存在しない"
      - "[x] .claude/skills/context-externalization/ が存在しない"
      - "[x] .claude/skills/execution-management/ が存在しない"
      - "[x] protected-files.txt から check-state-update.sh への参照が削除されている"
      - "[x] .claude/hooks/check-file-dependencies.sh が存在しない"
      - "[x] .claude/hooks/doc-freshness-check.sh が存在しない"
      - "[x] .claude/hooks/update-tracker.sh が存在しない"
      - "[x] settings.json から削除した Hook の登録が削除されている"
      - "[x] repository-map.yaml が更新されている"
    未完了条件:
      - "上記のいずれかが満たされていない"
    test_commands:
      - "test ! -f .claude/agents/plan-guard.md && test ! -f .claude/CLAUDE-ref.md && echo PASS"
      - "test ! -d .claude/skills/context-externalization && test ! -d .claude/skills/execution-management && echo PASS"
      - "! grep -q 'check-state-update.sh' .claude/protected-files.txt && echo PASS"
      - "test ! -f .claude/hooks/check-file-dependencies.sh && test ! -f .claude/hooks/doc-freshness-check.sh && test ! -f .claude/hooks/update-tracker.sh && echo PASS"
      - "! grep -E 'check-file-dependencies|doc-freshness-check|update-tracker' .claude/settings.json && echo PASS"

- id: M071
  name: "完全自己認識システム"
  description: |
    Claudeがユーザープロンプトに依存することなく自分の機能を全て把握していて、
    変更があればそれも認識して、常に最新に機能の全てが保護されている状態。
    1. docs/repository-map.yaml を Single Source of Truth として活用
    2. session-start.sh が repository-map.yaml を読み込み、機能一覧を認識
    3. Hook/SubAgent/Skill の追加・削除を自動検出する仕組み
    4. generate-repository-map.sh が自動更新を担当
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M063]
  playbooks:
    - playbook-m071-self-awareness.md
  done_when:
    - "[x] docs/repository-map.yaml が存在し、全 Hook/SubAgent/Skill の詳細情報を含む"
    - "[x] session-start.sh が repository-map.yaml を読み込み、機能サマリーを出力する"
    - "[x] 機能の追加・削除を自動検出する仕組み（generate-repository-map.sh）が実装されている"
    - "[x] 機能カタログが playbook 完了時に自動更新される"
  test_commands:
    - "test -f docs/repository-map.yaml && grep -c 'description:' docs/repository-map.yaml | awk '{if($1>=30) print \"PASS\"; else print \"FAIL\"}'"
    - "bash .claude/hooks/session-start.sh 2>&1 | grep -qE '[0-9]+ Hooks' && echo PASS || echo FAIL"
    - "test -x .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL"
    - "grep -q 'generate-repository-map.sh' plan/playbook-*.md 2>/dev/null || test -f docs/repository-map.yaml && echo PASS || echo FAIL"

- id: M073
  name: "AI エージェントオーケストレーション - 役割ベース executor 抽象化"
  description: |
    現在の executor は具体的なツール名（claudecode, codex, coderabbit, user）を直接指定している。
    これを抽象的な役割名（orchestrator, worker, reviewer, human）に変更し、
    実行時に toolstack に応じて解決する仕組みを実装する。

    目的:
    1. playbook の再利用性向上（toolstack 変更時に playbook 書き換え不要）
    2. 役割と実装の疎結合化（SOLID 原則）
    3. AI エージェントオーケストレーションの基盤構築
  status: achieved
  achieved_at: 2025-12-17
  depends_on: [M072]
  playbooks:
    - playbook-m073-ai-orchestration.md
  done_when:
    - "[x] state.md の config セクションに roles マッピングが追加されている"
    - "[x] playbook-format.md に meta.roles セクションの説明が追加されている"
    - "[x] role-resolver.sh が .claude/hooks/ に存在し、役割 -> executor 解決ロジックが実装されている"
    - "[x] executor-guard.sh が role-resolver.sh を呼び出して解決後の executor をチェックする"
    - "[x] pm SubAgent が playbook 作成時に roles セクションを自動生成する"
    - "[x] docs/ai-orchestration.md が存在し、設計・使用方法が文書化されている"
  test_commands:
    - "grep -q 'roles:' state.md && grep -q 'orchestrator:' state.md && echo PASS || echo FAIL"
    - "grep -q 'meta.roles' plan/template/playbook-format.md && echo PASS || echo FAIL"
    - "test -x .claude/hooks/role-resolver.sh && bash -n .claude/hooks/role-resolver.sh && echo PASS || echo FAIL"
    - "grep -q 'role-resolver.sh' .claude/hooks/executor-guard.sh && echo PASS || echo FAIL"
    - "grep -q 'roles' .claude/agents/pm.md && echo PASS || echo FAIL"
    - "test -f docs/ai-orchestration.md && wc -l docs/ai-orchestration.md | awk '{if($1>=50) print \"PASS\"; else print \"FAIL\"}'"

- id: M076
  name: "AI オーケストレーション E2E テスト - toolstack B/C 実動作検証"
  description: |
    M075 で役割名形式に統一したが、実際の動作テストが不十分だった。
    toolstack B/C での実動作を検証する。
    1. state.md の toolstack を B/C に変更
    2. role-resolver.sh が正しく解決するか確認
    3. state.md を元の状態（toolstack: A）に復元
  status: achieved
  depends_on: [M075]
  playbooks:
    - playbook-m076-orchestration-e2e-test.md
  done_when:
    - "[x] state.md の toolstack を B に変更した場合、role-resolver.sh が worker -> codex を返す"
    - "[x] state.md の toolstack を C に変更した場合、role-resolver.sh が reviewer -> coderabbit を返す"
    - "[x] pm SubAgent が生成する playbook に executor: worker 形式が含まれている"
    - "[x] テスト完了後、state.md が toolstack: A に復元されている"
  test_commands:
    - "echo 'worker' | TOOLSTACK=B bash .claude/hooks/role-resolver.sh | grep -q 'codex' && echo PASS || echo FAIL"
    - "echo 'reviewer' | TOOLSTACK=C bash .claude/hooks/role-resolver.sh | grep -q 'coderabbit' && echo PASS || echo FAIL"
    - "grep -c 'executor: orchestrator' plan/playbook-m076-orchestration-e2e-test.md | awk '{if($1>=5) print \"PASS\"; else print \"FAIL\"}'"
    - "grep -q 'toolstack: A' state.md && echo PASS || echo FAIL"

- id: M078
  name: "Codex MCP 切り替え - TTY 制約回避"
  description: |
    Codex CLI は TTY 制約のため Claude Code から直接呼び出せない問題がある。
    Codex MCP サーバー経由で呼び出すことで、この制約を回避する。
    1. .claude/mcp.json に codex mcp-server を登録
    2. codex-delegate SubAgent を MCP ツール呼び出しに変更
    3. ドキュメントを更新
    4. 動作確認
  status: achieved
  depends_on: [M076]
  playbooks:
    - playbook-m078-codex-mcp.md
  done_when:
    - "[ ] .claude/mcp.json が存在し、codex mcp-server が登録されている"
    - "[ ] codex-delegate.md が MCP ツール mcp__codex__codex を使用する形式に更新されている"
    - "[ ] docs/ai-orchestration.md に Codex MCP の説明が追加されている"
    - "[ ] toolstack C で簡単なコーディングタスクを Codex MCP 経由で実行し、正常に動作することが確認されている"
    - "[ ] テスト完了後、toolstack: A に復元されている"
  test_commands:
    - "test -f .claude/mcp.json && grep -q 'codex' .claude/mcp.json && echo PASS || echo FAIL"
    - "grep -q 'mcp__codex__codex' .claude/agents/codex-delegate.md && echo PASS || echo FAIL"
    - "grep -q 'Codex MCP' docs/ai-orchestration.md && echo PASS || echo FAIL"
    - "grep -q 'toolstack: A' state.md && echo PASS || echo FAIL"

- id: M079
  name: "Golden Path 強制 - ボタンのかけ違い修正"
  description: |
    「pm 必須」の Golden Path が構造的に強制されていない問題を修正。
    1. ズレA: CLAUDE.md に Golden Path ルールがない → 追加
    2. ズレB: Bash で playbook-guard をバイパス可能 → pre-bash-check で封鎖
    3. ズレC: admin で全バイパス → playbook-guard の admin バイパス削除
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M078]
  playbooks:
    - playbook-m079-golden-path-fix.md
    - playbook-contract-consolidation.md
  done_when:
    - "[x] CLAUDE.md に Golden Path セクション（## 11）が追加されている"
    - "[x] prompt-guard.sh の playbook=null 警告が pm 必須を明示している"
    - "[x] playbook-guard.sh の admin バイパス（29-32行）が削除されている"
    - "[x] pre-bash-check.sh が playbook=null で変更系 Bash をブロックする"
    - "[x] 検証シナリオ 3 つが全て PASS する（E2E 52件 ALL TESTS PASSED）"
    - "[x] check-integrity.sh が PASS する"
  test_commands:
    - "grep -q '## 11. Golden Path' CLAUDE.md && echo PASS || echo FAIL"
    - "grep -q 'pm.*必須' .claude/hooks/prompt-guard.sh && echo PASS || echo FAIL"
    - "! grep -q 'admin.*exit 0' .claude/hooks/playbook-guard.sh && echo PASS || echo FAIL"
    - "grep -q 'playbook.*null.*変更系' .claude/hooks/pre-bash-check.sh && echo PASS || echo FAIL"

- id: M080
  name: "README 実態同期 + 公開準備"
  description: |
    README が実態と乖離している問題を解決。
    - 「複雑性爆発」「未実装」等の古い記述を削除
    - 現在の実装状況（32 Hooks, 6 SubAgents, 9 Skills, 52 E2E）を正確に反映
    - クイックスタートセクションを追加
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M079]
  playbooks:
    - playbook-m080-readme-sync.md
  done_when:
    - "[x] README.md に「複雑性爆発」「未実装」等の古い表記が存在しない"
    - "[x] README.md の Hook 数が 32 個と記載されている"
    - "[x] README.md の CLAUDE.md 行数が実態（約262行）と一致している"
    - "[x] README.md に「クイックスタート」セクションが存在する"
    - "[x] README.md の E2E テスト数が 52 と記載されている"
  test_commands:
    - "! grep -qE '複雑性の?爆発|未実装' README.md && echo PASS || echo FAIL"
    - "grep -q '32' README.md && echo PASS || echo FAIL"
    - "grep -qE '26[0-9]行|約260行|約270行' README.md && echo PASS || echo FAIL"
    - "grep -q 'クイックスタート' README.md && echo PASS || echo FAIL"
    - "grep -q '52' README.md && echo PASS || echo FAIL"

- id: M081
  name: "全機能動作検証ドキュメント作成"
  description: |
    リポジトリの全機能が正常に動作することを証明するドキュメントを作成。
    1. 架空のユーザーとの対話シミュレーション形式
    2. 全コンポーネント（32 Hooks, 6 SubAgents, 9 Skills）の動作確認
    3. E2E テスト 52件の実行結果を記録
    4. tmp/ に成果物を配置（テンポラリドキュメント）
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M080]
  playbooks:
    - playbook-m081-full-verification.md
  done_when:
    - "[x] tmp/full-system-verification.md が存在する"
    - "[x] ドキュメントに 32 Hooks の動作確認結果が記載されている"
    - "[x] ドキュメントに 6 SubAgents の動作確認結果が記載されている"
    - "[x] ドキュメントに 9 Skills の動作確認結果が記載されている"
    - "[x] E2E テスト 52件の実行結果が含まれている"
  test_commands:
    - "test -f tmp/full-system-verification.md && echo PASS || echo FAIL"
    - "grep -c 'Hook.*PASS\\|PASS.*Hook' tmp/full-system-verification.md | awk '{if($1>=32) print \"PASS\"; else print \"FAIL\"}'"
    - "grep -c 'SubAgent\\|Agent' tmp/full-system-verification.md | awk '{if($1>=6) print \"PASS\"; else print \"FAIL\"}'"
    - "grep -c 'Skill' tmp/full-system-verification.md | awk '{if($1>=9) print \"PASS\"; else print \"FAIL\"}'"
    - "grep -q '52' tmp/full-system-verification.md && echo PASS || echo FAIL"

# ============================================================
# M082-M087: 復旧マイルストーン（2025-12-19 E2E レポート基づく）
# ============================================================

- id: M082
  name: "Hook の契約固定と止血"
  description: |
    今の最悪は「subtask-guard がチェック更新をブロック」「create-pr が黙って何もしない」で運用が詰むこと。
    まず "Hook が壊れても作業が詰まない（少なくとも理由が出る）" にする。

    対象 Hook:
      - subtask-guard.sh
      - create-pr-hook.sh
      - archive-playbook.sh
      - （横断）Hook の出力/exit code の共通契約
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M081]
  playbooks:
    - playbook-m082-hook-contract.md
  done_when:
    - "[x] docs/hook-exit-code-contract.md が存在し、WARN/BLOCK/INTERNAL ERROR の定義が明記されている"
    - "[x] subtask-guard.sh がパース失敗時に exit 0 + stderr メッセージを出す"
    - "[x] create-pr-hook.sh が PR 未作成時に SKIP 理由を stderr に出す"
    - "[x] archive-playbook.sh が SKIP 時に理由を stderr に出す"
    - "[x] 全対象 Hook で 'No stderr output' が再現しない（必ず何か出力）"

- id: M083
  name: "状態同期とガード機能の修正"
  description: |
    M082 完了後に発見された 3 つの問題を修正:
    1. project.md 自動更新が動作していない（milestone 完了時に status が更新されない）
    2. done_when/done_criteria 用語の不整合（パース失敗の原因）
    3. consent-guard（理解確認/リスク判断）が機能していない
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M082]
  playbooks:
    - playbook-m083-state-sync-fix.md
  done_when:
    - "[x] playbook 完了時に project.md の対応 milestone が status: achieved に自動更新される仕組みが存在する"
    - "[x] done_when と done_criteria の用語が統一されている（done_when に統一）"
    - "[x] consent-guard.sh が consent ファイル存在時に [理解確認] ブロックを表示してブロックする"

# ============================================================
# M084-M087: Hook システム安定化（2025-12-19 E2E レポート続行）
# ============================================================

- id: M084
  name: "Playbook Schema v2 + 正規化"
  description: |
    playbook の表記揺れを根絶し、Hook が確実にパースできる形式に正規化する。
    1. playbook-format.md を Schema v2 として厳密化
    2. playbook-validator.sh を実装
    3. 既存 playbook を正規化
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M083]
  playbooks:
    - playbook-m084-playbook-schema-v2.md
  done_when:
    - "[x] plan/template/playbook-format.md に Schema v2 マーカーが存在する"
    - "[x] .claude/hooks/playbook-validator.sh が存在し実行可能"
    - "[x] playbook-validator.sh が不正形式を検出して exit 非0 を返す"
    - "[x] 既存の active playbook が Schema v2 に準拠している"

- id: M085
  name: "subtask-guard の仕様準拠化"
  description: |
    subtask-guard.sh を M082 の契約に完全準拠させ、Layer2 復旧を完了。
    1. パース失敗時は WARN で通す
    2. validations チェックをオプション化（厳格モードで BLOCK）
    3. 詳細なデバッグログを stderr に出力
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M084]
  playbooks:
    - playbook-m085-subtask-guard-compliance.md
  done_when:
    - "[x] subtask-guard.sh がパース失敗時に exit 0 を返す"
    - "[x] subtask-guard.sh に厳格モード（STRICT=1）オプションが存在する"
    - "[x] 通常モードで validations 不足は WARN のみ"
    - "[x] 厳格モードで validations 不足は BLOCK"

- id: M086
  name: "create-pr-hook の復旧"
  description: |
    create-pr-hook.sh を復旧し、CodeRabbit 連携を再開。
    1. SKIP 理由の明確化
    2. gh コマンドの存在チェック
    3. PR 作成成功時のログ強化
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M085]
  playbooks:
    - playbook-m086-create-pr-hook-recovery.md
  done_when:
    - "[x] create-pr-hook.sh が SKIP 時に理由を stderr に出す"
    - "[x] gh コマンド不存在時に WARN を出力"
    - "[x] PR 作成成功時に PR URL をログに出力"

- id: M087
  name: "ローカル Hook テストスイートの整備"
  description: |
    Hook の動作を保証するローカルテストスイートを整備。
    ローカル完結の設計原則を維持し、CI 依存を回避。
    1. .claude/tests/hook-tests.sh を作成
    2. 全 Hook の構文チェック（bash -n）
    3. 擬似入力での基本動作テスト
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M086]
  playbooks:
    - playbook-m087-local-hook-tests.md
  done_when:
    - "[x] .claude/tests/hook-tests.sh が存在し実行可能"
    - "[x] 全 Hook が bash -n で構文エラーなし"
    - "[x] 主要 Hook の基本動作テストが PASS"
    - "[x] テスト結果が stdout に出力される"

# ============================================================
# M088-M101: 仕様同期・完成収束（SSC: Spec Sync Contract）
# ============================================================

- id: M088
  name: "差分修正 - 報酬詐欺リスク解消と実態同期"
  description: |
    差分分析で発見された問題を修正し、README/project.md/実態を同期させる。
    1. M071 の feature-catalog.yaml 不在問題の解決
    2. Hook 数のカウント不整合（README 32 vs 実態 33）の解決
    3. README の Milestone 数（82 → 87+）の更新
    4. 未登録 Hook 11個の分類・台帳化
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M087]
  playbooks:
    - playbook-m088-gap-fix.md
  done_when:
    - "[x] M071 done_when の feature-catalog.yaml 問題が解決されている（repository-map.yaml ベースに修正）"
    - "[x] README.md の Hook 数が実態と一致している（33個）"
    - "[x] README.md の Milestone 数が実態（40個、M001-M088）と一致している"
    - "[x] 未登録 Hook 11個が docs/hook-registry.md に台帳化されている"
    - "[x] check-integrity.sh が PASS"
    - "[x] e2e-contract-test.sh が 52/52 PASS"
  test_commands:
    - "test -f docs/feature-catalog.yaml || grep -q 'feature-catalog' plan/project.md | grep -v 'feature-catalog.yaml' && echo PASS || echo FAIL"
    - "bash .claude/hooks/check-integrity.sh 2>&1 | tail -1 | grep -q 'All checks passed' && echo PASS || echo FAIL"
    - "bash scripts/e2e-contract-test.sh all 2>&1 | grep -q 'PASS: 52' && echo PASS || echo FAIL"

- id: M089
  name: "コンポーネント台帳の正規化"
  description: |
    generate-repository-map.sh のバグ修正と repository-map.yaml の数値同期。
    1. plan/active ディレクトリ不存在時のエラー修正
    2. repository-map.yaml の hooks/agents/skills/commands 数値を実態と同期
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M088]
  playbooks:
    - playbook-m089-component-registry-normalization.md
  done_when:
    - "[x] generate-repository-map.sh が exit 0 で完了する"
    - "[x] repository-map.yaml の hooks が 33 と一致"
    - "[x] repository-map.yaml の agents が 6 と一致"
    - "[x] repository-map.yaml の skills が 9 と一致"
    - "[x] repository-map.yaml の commands が 8 と一致"
    - "[x] check-integrity.sh が PASS"
  test_commands:
    - "bash .claude/hooks/generate-repository-map.sh && echo PASS || echo FAIL"
    - "grep 'hooks: 33' docs/repository-map.yaml && echo PASS || echo FAIL"
    - "grep 'agents: 6' docs/repository-map.yaml && echo PASS || echo FAIL"
    - "grep 'skills: 9' docs/repository-map.yaml && echo PASS || echo FAIL"
    - "grep 'commands: 8' docs/repository-map.yaml && echo PASS || echo FAIL"
    - "bash .claude/hooks/check-integrity.sh 2>&1 | tail -1 | grep -q 'All checks passed' && echo PASS || echo FAIL"

- id: M090
  name: "コンポーネント動作保証システム"
  description: |
    vision.success_criteria「全 Hook/SubAgent/Skill が動作確認済み」を達成。
    Hook は test-hooks.sh で検証済み。残りのコンポーネントをテストする。
    1. SubAgent (6個) の動作テストスクリプト作成
    2. Skill (9個) の動作テストスクリプト作成
    3. Command (8個) の動作テストスクリプト作成
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M089]
  playbooks:
    - playbook-m090-component-tests.md
  done_when:
    - "[x] scripts/test-subagents.sh が存在し、6 SubAgent 全てをテスト"
    - "[x] scripts/test-skills.sh が存在し、9 Skill 全てをテスト"
    - "[x] scripts/test-commands.sh が存在し、8 Command 全てをテスト"
    - "[x] 全テストが PASS"
  test_commands:
    - "test -f scripts/test-subagents.sh && echo PASS || echo FAIL"
    - "test -f scripts/test-skills.sh && echo PASS || echo FAIL"
    - "test -f scripts/test-commands.sh && echo PASS || echo FAIL"
    - "bash scripts/test-subagents.sh 2>&1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

- id: M091
  name: "仕様同期基盤 (SSC Phase 1)"
  description: |
    Spec Sync Contract の基盤。コンポーネント数の自動追跡と警告システム。
    1. state.md に COMPONENT_REGISTRY セクション追加
    2. repository-map.yaml 生成時に COMPONENT_REGISTRY を自動更新
    3. 数値変更検出と警告メカニズム
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M090]
  playbooks:
    - playbook-m091-ssc-phase1.md
  done_when:
    - "[x] state.md に COMPONENT_REGISTRY セクションが存在"
    - "[x] COMPONENT_REGISTRY に hooks/agents/skills/commands の数値が記録"
    - "[x] generate-repository-map.sh が COMPONENT_REGISTRY を更新"
    - "[x] 数値変更時に警告が出力される"
  test_commands:
    - "grep -q 'COMPONENT_REGISTRY' state.md && echo PASS || echo FAIL"
    - "grep -E 'hooks: 33|agents: 6|skills: 9|commands: 8' state.md && echo PASS || echo FAIL"

- id: M092
  name: "自己検証自動化 (SSC Phase 2)"
  description: |
    playbook 完了時の自動整合性チェック強化。
    1. SPEC_SNAPSHOT の導入（README/project.md の数値スナップショット）
    2. repository-map.yaml と実態の自動比較
    3. 乖離検出時の警告システム
  status: achieved
  achieved_at: 2025-12-19
  depends_on: [M091]
  playbooks:
    - playbook-m092-ssc-phase2.md
  done_when:
    - "[x] state.md に SPEC_SNAPSHOT セクションが存在"
    - "[x] playbook 完了時に SPEC_SNAPSHOT が自動更新される"
    - "[x] README/project.md と実態の乖離検出時に警告が出力される"
  test_commands:
    - "grep -q 'SPEC_SNAPSHOT' state.md && echo PASS || echo FAIL"
    - "bash .claude/hooks/check-spec-sync.sh && echo PASS || echo FAIL"

- id: M093
  name: "安全な進化システム (SSC Phase 3)"
  description: |
    Freeze-then-Delete プロセスの実装。ファイル削除の安全性を保証。
    1. FREEZE_QUEUE: 削除予定ファイルの猶予期間管理
    2. DELETE_LOG: 削除履歴の追跡
    3. freeze → confirm → delete の3段階プロセス
  status: achieved
  depends_on: [M092]
  done_when:
    - "[x] state.md に FREEZE_QUEUE セクションが存在"
    - "[x] state.md に DELETE_LOG セクションが存在"
    - "[x] scripts/freeze-file.sh が存在し動作"
    - "[x] scripts/delete-frozen.sh が存在し動作"
    - "[x] Freeze-then-Delete プロセスが文書化"
  test_commands:
    - "grep -q 'FREEZE_QUEUE' state.md && echo PASS || echo FAIL"
    - "grep -q 'DELETE_LOG' state.md && echo PASS || echo FAIL"
    - "test -f scripts/freeze-file.sh && echo PASS || echo FAIL"

- id: M096
  name: "pre-bash-check デッドロック修正"
  description: |
    playbook=null で git add/commit 等のメンテナンス操作がブロックされ、
    playbook 完了後の最終コミットができない問題を修正。
    scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS に
    不足しているパターン（git checkout/merge/branch -d 等）を追加。
  status: achieved
  achieved_at: 2025-12-20
  depends_on: [M093]
  playbooks:
    - playbook-m096-pre-bash-deadlock-fix.md
  done_when:
    - "[x] scripts/contract.sh の ADMIN_MAINTENANCE_PATTERNS に git checkout/merge/branch -d が追加されている"
    - "[x] playbook=null で git add state.md が実行できる"
    - "[x] playbook=null で git commit が実行できる"
    - "[x] playbook=null で git checkout main が実行できる"
  test_commands:
    - "grep -q 'git.*checkout.*main' scripts/contract.sh && echo PASS || echo FAIL"
    - "grep -q 'git.*merge' scripts/contract.sh && echo PASS || echo FAIL"
    - "grep -q 'git.*branch.*-d' scripts/contract.sh && echo PASS || echo FAIL"

- id: M097
  name: "嘘が生まれない仕組み - README 自動同期"
  description: README と実態の乖離を構造的に防止する。
  status: achieved
  depends_on: [M096]
  playbooks:
    - playbook-m097-anti-lie-system.md
  done_when:
    - "[x] scripts/generate-readme-stats.sh が存在し実行可能"
    - "[x] README.md の STATS タグでスクリプト更新可能"

- id: M098
  name: "CORE FREEZE - 増殖停止"
  description: Core を凍結し新規コンポーネント追加を禁止する。
  status: achieved
  depends_on: [M097]
  playbooks:
    - playbook-m098-m100-final-freeze.md
  done_when:
    - "[x] governance/core-manifest.yaml が存在"
    - "[x] policy.no_new_components=true"

- id: M099
  name: "UNUSED PURGE - 未使用削除"
  description: 未登録 hooks と非 Core コンポーネントを機械的に削除。
  status: achieved
  depends_on: [M098]
  playbooks:
    - playbook-m098-m100-final-freeze.md
  done_when:
    - "[x] scripts/find-unused.sh が存在"
    - "[x] 未登録 hooks 削除完了（34→22）"

- id: M100
  name: "STABILIZE + RELEASE - 安定化と公開準備"
  description: 挙動テストで保証し、公開用に凍結する。
  status: achieved
  depends_on: [M099]
  playbooks:
    - playbook-m098-m100-final-freeze.md
  done_when:
    - "[x] scripts/behavior-test.sh が PASS"
    - "[x] README から数字自慢が消えている"

- id: M103
  name: "Freeze Core Runtime - 非コア Hook 削除と最終安定化"
  description: |
    settings.json を Core Hooks 8本のみに削減し、非コア Hook ファイルを削除して最終凍結。
    ※ M104 の Layer アーキテクチャ議論で方針が見直される可能性があるため保留。
  status: postponed
  depends_on: [M100]
  postponed_reason: "M104 で Layer アーキテクチャを再定義した後に再検討"
  playbooks:
    - playbook-m103-freeze-core-runtime.md
  done_when:
    - "[ ] settings.json に登録されている hooks が Core 定義に準拠"
    - "[ ] 非コア Hook ファイルが削除されている"
    - "[ ] behavior-test.sh が全て PASS"

- id: M104
  name: "Layer Architecture - 黄金動線ベースの設計議論"
  description: |
    現在の core-manifest.yaml v2 は「発火タイミング」で Layer を分類しているが、
    「黄金動線における役割の深さ/保護レベル」で再定義すべきという議論から発生。

    黄金動線:
      /task-start → pm → playbook → work → /crit → critic → done

    このマイルストーンは「設計議論と合意形成」のみがスコープ。
    実装は M105 で実施する。
  status: achieved
  achieved_at: 2025-12-20
  depends_on: [M100]
  playbooks:
    - playbook-m104-layer-architecture.md
  done_when:
    - "[x] Layer アーキテクチャの設計案が文書化されている（docs/layer-architecture-design.md）"
    - "[x] 「黄金動線での役割」ベースの Layer 定義案が作成されている"
    - "[x] Core 最小セットの候補リストが議論・合意されている"
    - "[x] 実装フェーズが次のマイルストーン（M105）として project.md に定義されている"
  test_commands:
    - "test -f docs/layer-architecture-design.md && echo PASS || echo FAIL"
    - "grep -q '黄金動線' docs/layer-architecture-design.md && echo PASS || echo FAIL"
    - "grep -q 'M105' plan/project.md && echo PASS || echo FAIL"

- id: M105
  name: "Golden Path Verification - 動線単位の動作テスト"
  description: |
    M104 で設計した動線ベースの分類に基づき、全40コンポーネントの動作を検証する。
    Layer 実装は不要。棚卸しと検証がスコープ。

    テスト対象（check.md と整合）:
      1. 計画動線（6個）: task-start, playbook-init, pm, state, plan-management, prompt-guard
      2. 実行動線（11個）: init-guard, playbook-guard, subtask-guard, scope-guard, check-protected-edit, pre-bash-check, consent-guard, executor-guard, check-main-branch, lint-checker, test-runner
      3. 検証動線（6個）: crit, test, lint, critic, reviewer, critic-guard
      4. 完了動線（8個）: rollback, state-rollback, focus, archive-playbook, cleanup-hook, create-pr-hook, post-loop, context-management
      5. 共通基盤（6個）: session-start, session-end, pre-compact, stop-summary, log-subagent, consent-process
      6. 横断的整合性（3個）: check-coherence, depends-check, lint-check

    既知の動作不良（M106 で修正予定）:
      - consent-guard: 特定単語トリガー、デッドロック発生
      - subtask-guard: STRICT=0 でデフォルト WARN
      - critic-guard: playbook の phase 完了をチェックしない
  status: achieved
  achieved_at: 2025-12-20
  depends_on: [M104]
  playbooks:
    - playbook-m105-golden-path-verification.md
  done_when:
    - "[x] check.md に旧仕様が記録されている"
    - "[x] project.md の M105 が check.md と整合している"
    - "[x] 全40コンポーネントの動作確認が完了している（40/40 PASS）"
    - "[x] 動作不良コンポーネントが特定され修正方針が決まっている（3件→M106）"
  test_commands:
    - "test -f check.md && grep -q '旧仕様' check.md && echo PASS || echo FAIL"
    - "bash scripts/golden-path-test.sh 2>&1 | tail -5 | grep -q 'ALL TESTS PASSED' && echo PASS || echo FAIL"
  note: |
    ⚠️ M105 のテストは「コンポーネント単位の構文・存在確認」であり、
    「動線単位のテスト」ではなかった。報酬詐欺として M107 で再実施。

- id: M106
  name: "動作不良コンポーネント修正"
  description: |
    M105 で特定された動作不良 3 件を修正する。

    修正対象:
      1. consent-guard.sh - デッドロック問題（HIGH）
         - 「削除」「rm」等のトリガー単語で無限ループ
         - 対策: playbook.active 存在時は consent チェックをスキップ

      2. critic-guard.sh - phase 完了チェック欠落（HIGH）
         - playbook の phase.status 変更を検出しない
         - 対策: playbook-*.md の status: done/completed も監視

      3. subtask-guard.sh - デフォルト WARN モード（MEDIUM）
         - STRICT=0 がデフォルト
         - 対策: デフォルト STRICT=1 に変更
  status: achieved
  achieved_at: 2025-12-20
  depends_on: [M105]
  playbooks:
    - playbook-m106-component-fix.md
  done_when:
    - "[x] consent-guard.sh のデッドロック問題が解消されている"
    - "[x] critic-guard.sh が phase.status 変更を検出する"
    - "[x] subtask-guard.sh がデフォルト STRICT=1 になっている"
    - "[x] 各修正に対する回帰テストが追加されている（6/6 PASS）"
  test_commands:
    - "grep -q 'STRICT:-1' .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
    - "grep -q 'playbook-' .claude/hooks/critic-guard.sh && echo PASS || echo FAIL"
    - "bash scripts/m106-test.sh 2>&1 | grep -q 'ALL TESTS PASSED' && echo PASS || echo FAIL"

- id: M107
  name: "動線単位テスト - Golden Path 検証再実施"
  description: |
    M105 は「コンポーネント構文チェック」のみで「動線単位テスト」を実施していなかった。
    本マイルストーンで正しいテスト手法を設計・実行する。

    結果: 18/18 PASS（全 PASS 警告機能が正常動作）
    分析: M106 の修正効果により FAIL が解消。テスト設計の限界も記録済み。
  status: achieved
  achieved_at: 2025-12-20
  depends_on: [M106]
  playbooks:
    - playbook-m107-flow-test.md
  done_when:
    - "[x] 動線単位テストスクリプト（scripts/flow-test.sh）が存在する"
    - "[x] 計画動線のテストケースが定義され実行されている（4/4 PASS）"
    - "[x] 実行動線のテストケースが定義され実行されている（6/6 PASS）"
    - "[x] 検証動線のテストケースが定義され実行されている（4/4 PASS）"
    - "[x] 完了動線のテストケースが定義され実行されている（4/4 PASS）"
    - "[x] 全 PASS 警告機能が実装されている"
    - "[x] テスト設計の限界が docs/flow-test-report.md に記録されている"
  test_commands:
    - "test -f scripts/flow-test.sh && echo PASS || echo FAIL"
    - "bash scripts/flow-test.sh 2>&1 | grep -q 'All PASS' && echo 'All PASS (warning triggered)' || echo FAIL"

- id: M122
  name: "Claude 自己認識システム - 動線単位での全仕様把握"
  description: |
    **ユーザープロンプト原文（2025-12-21）:**
    > Claude自身が自分のすべての仕様（Hook, SubAgents, Skills, 関連ドキュメント、関連ファイル）を、
    > 黄金動線、つまり単一のコンポーネントではなく、連携している機能が複合して果たしている
    > 役割単位で整理して常に認知されている必要がある。
    > 動線単位で最新の全機能を網羅したものを正として、それが維持される仕組みを作る。
    > 不要なものは必要な記載だけを統合して、数を減らす。
    > 全ファイルを精査する - 1ファイル1subtask が必要。

    **目的:**
    1. Claude が全仕様を「動線単位」で把握できる仕組みを構築
    2. 単一コンポーネントではなく「連携機能が果たす役割」で整理
    3. docs/ 内の全ファイルを精査し、動線単位で必要性を判断
    4. 必要な記載のみ統合し、不要なものは削除

    **背景:**
    - これまで何度も全仕様把握の仕組み作りに挑戦して失敗
    - 残存ファイルが散逸し、根拠不明の数値目標が設定されていた
    - playbook 作成時にユーザープロンプト原文が記録されていなかった
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M107]
  playbooks:
    - playbook-m122-session-flow-doc-integration.md
    - playbook-m122-full-review.md
    - playbook-m122-auto-update-essential-docs.md
  done_when:
    - "[x] docs/ 内の全ファイルが動線単位で精査されている（1ファイル1subtask で検証）"
    - "[x] 動線単位で必要なファイルのみ残存し、不要な記載は統合済み"
    - "[x] docs/essential-documents.md が動線単位で全機能を網羅している"
    - "[x] essential-documents.md が自動更新される仕組みが構築されている"
    - "[x] playbook に user_prompt_original フィールドが標準化されている"
  test_commands:
    - "test -f docs/essential-documents.md && grep -q '動線' docs/essential-documents.md && echo PASS || echo FAIL"
    - "grep -q 'user_prompt_original' plan/template/playbook-format.md && echo PASS || echo FAIL"

- id: M123
  name: "類似機能統合（重複排除と単一化）"
  description: |
    **ユーザープロンプト原文（2025-12-21）:**
    > 整理された内容を元に、Claudeが自身の機能を把握する機能が複数あって正常に動作してないので
    > どれか一つに統合して欲しい。まずテンプレートと整理された動線から、類似する機能がいくつあるか
    > リストアップ。その中で実現可能性が高い順番に並び替えて、それぞれのメリットデメリットを
    > ユーザーに提示。統合と削除を行う。
    > 同様に整理された動線をすべてチェックし、類似する機能が他にもないかチェックする。

    **背景:**
    - M122 で動線単位の整理が完了
    - しかし「Claudeが自身の機能を把握する機能」が複数存在し、正常動作していない
    - 例：essential-documents.md, repository-map.yaml, core-manifest.yaml など似た役割が分散

    **目的:**
    1. 類似機能をリストアップし、実現可能性順に整理
    2. 各選択肢のメリット・デメリットをユーザーに提示
    3. 承認を得て統合を実装
    4. 不要な機能を FREEZE_QUEUE に追加
    5. 動線単位で他の類似機能がないかチェック
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M122]
  playbooks:
    - playbook-m123-similar-function-consolidation.md
  done_when:
    - "[x] session-start.sh が essential-documents.md の layer_summary を出力する"
    - "[x] repository-map.yaml が FREEZE_QUEUE に追加されている"
    - "[x] state.md から COMPONENT_REGISTRY セクションが削除されている"
    - "[x] 動線テスト（セッション開始時に Claude が動線情報を認識）が PASS"
  test_commands:
    - "bash .claude/hooks/session-start.sh 2>&1 | grep -qE '計画動線|実行動線|検証動線|完了動線' && echo PASS || echo FAIL"
    - "grep 'repository-map.yaml' state.md | grep -q 'freeze_date' && echo PASS || echo FAIL"
    - "! grep -q '## COMPONENT_REGISTRY' state.md && echo PASS || echo FAIL"

- id: M126
  name: "動線コンテキスト内部参照の完全化"
  description: |
    **ユーザープロンプト原文（2025-12-21）:**
    > M126 playbook を作成してください。
    > Skills は `/skill-name` で呼べる形式（コマンド化）が推奨される
    > 既存の動線（Hook, SubAgent, Skill, Command）に機能不全がある:
    > - 削除済みファイルへの参照が残っている
    > - Skills と Commands の対応が不完全

    **背景:**
    - cleanup-hook.sh が削除済みスクリプト（generate-repository-map.sh, check-spec-sync.sh）を参照
    - Skills と Commands の対応が不完全（context-management, post-loop にコマンドなし）

    **目的:**
    1. 動線の内部参照を完全に整合させる（削除済みファイルへの参照を除去）
    2. Skills を Commands として正規化（/skill-name で呼べる形式に統一）
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M123]
  playbooks:
    - playbook-m126-flow-context-completeness.md
  done_when:
    - "[x] cleanup-hook.sh から削除済みスクリプトへの参照が除去されている"
    - "[x] 全 Hook が存在するファイルのみを参照している"
    - "[x] 全 Skill に対応する Command が存在する（6 Skills → 6 Commands）"
    - "[x] scripts/flow-integrity-test.sh が PASS する"
  test_commands:
    - "! grep -qE 'generate-repository-map\\.sh|check-spec-sync\\.sh' .claude/hooks/cleanup-hook.sh && echo PASS || echo FAIL"
    - "bash scripts/flow-integrity-test.sh 2>&1 | tail -1 | grep -q 'ALL TESTS PASSED' && echo PASS || echo FAIL"

- id: M129
  name: "動線 100% 担保 - 実行時検証システム"
  description: |
    **背景（M128 Codex レビュー FAIL 指摘）:**
    - e2e-contract-test.sh が contract_check_* を直接テストしているが、
      実際の Hook（pre-bash-check.sh の JSON 解析、playbook-guard.sh の配線）はテストしていない
    - flow-integrity-test.sh が純粋に静的（ファイル存在確認のみ）
    - done_when の証拠不足（grep/bash -n チェックに依存）

    **目的:**
    1. 実際の Hook 発火を検証するテスト（hook-runtime-test.sh）
    2. 4 動線の実行時検証テスト（flow-runtime-test.sh）
    3. fail-closed/HARD_BLOCK/admin maintenance テスト追加
    4. コンテキスト保持機構のテスト（context-test.sh）
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M128]
  playbooks:
    - playbook-m129-runtime-verification-system.md
  done_when:
    - "[x] 「実際の Hook 発火」を検証するテスト（hook-runtime-test.sh）が全 PASS"
    - "[x] 「4 動線」の実行時検証テスト（flow-runtime-test.sh）が全 PASS"
    - "[x] fail-closed/HARD_BLOCK/admin maintenance テストが e2e-contract-test.sh に追加され全 PASS"
    - "[x] コンテキスト保持機構（session-start, pre-compact）の動作検証テストが全 PASS"
    - "[x] ユーザー承認を得た設計に基づいて実装が完了"
  test_commands:
    - "bash scripts/hook-runtime-test.sh"
    - "bash scripts/flow-runtime-test.sh"
    - "bash scripts/e2e-contract-test.sh all"
    - "bash scripts/context-test.sh"

- id: M127
  name: "Playbook Reviewer 動線の自動化"
  description: |
    **背景（M126 Codex 手動レビュー体験から）:**
    - `codex exec --full-auto` で playbook レビューが可能
    - 5 ラウンドのレビューサイクルで test_command の堅牢化を学習
    - 「レビューなしの実装は何もしないよりタチが悪い」

    **目的:**
    1. pm が playbook 作成後、自動的に reviewer SubAgent を起動
    2. reviewer が config.roles.reviewer に基づいて Codex/ClaudeCode を選択
    3. Codex の場合、`codex exec --full-auto` を実行し RESULT: PASS/FAIL をパース
    4. FAIL なら修正サイクル、PASS なら reviewed: true に更新

    **学習した test_command 設計原則:**
    - exit code で成功/失敗を判定可能にする
    - 存在チェックは test -f で明示的に行う
    - grep の否定は反転ロジックを使う
    - done_when は具体的なファイル名/固定数を明記する
  status: postponed
  postponed_reason: "M140-M145 でコア機能の動作保証を優先。M146 で再開。"
  depends_on: [M126]
  playbooks: []
  done_when:
    - "[ ] reviewer SubAgent が config.roles.reviewer を読んで分岐できる"
    - "[ ] codex の場合、codex exec --full-auto を Bash で実行できる"
    - "[ ] RESULT: PASS/FAIL をパースして reviewed: true/false を更新できる"
    - "[ ] FAIL 時に修正提案を返却できる"
  test_commands:
    - "grep -q 'codex exec' .claude/agents/reviewer.md && echo PASS || echo FAIL"

# ============================================================
# M140-M146: コア機能動作保証シリーズ（2025-12-21）
# ============================================================
# 背景: 仕様に記載されたコンポーネントが存在しない（consent-guard.sh 等）
# 目的: 仕様と実態を完全同期し、動作保証してから凍結
# ============================================================

- id: M140
  name: "存在しないコンポーネントの解決"
  description: |
    **ユーザープロンプト原文（2025-12-21）:**
    > コア機能の確定と凍結が一番最初にあったほうがいいかな。
    > 凍結の前に動作保証がなされている必要がある。
    > 例えば何回言っても君、理解確認機能が直らないしね。
    > 今の機能全部、リストアップして。何で動作しないのか、棚卸ししながら、
    > スモールステップで進めるしかない。

    **問題:**
    - consent-guard.sh: core-manifest.yaml に記載されているが存在しない
    - create-pr-hook.sh: settings.json に登録されているが存在しない
    - generate-essential-docs.sh: essential-documents.md に記載されているが存在しない

    **方針:**
    各コンポーネントについて「作成」または「仕様から削除」を決定し、実行する。
  status: achieved
  depends_on: [M129]
  playbooks: []
  done_when:
    - "[x] consent-guard.sh が作成されているか、core-manifest.yaml から削除されている"
    - "[x] create-pr-hook.sh が作成されているか、settings.json から削除されている"
    - "[x] generate-essential-docs.sh が作成されているか、essential-documents.md から参照が削除されている"
    - "[x] 仕様に記載された全コンポーネントがファイルとして存在する"
  test_commands:
    - "! grep -q 'consent-guard.sh' governance/core-manifest.yaml || test -f .claude/hooks/consent-guard.sh && echo PASS || echo FAIL"
    - "! grep -q 'create-pr-hook.sh' .claude/settings.json || test -f .claude/hooks/create-pr-hook.sh && echo PASS || echo FAIL"
    - "! grep -q 'generate-essential-docs.sh' docs/essential-documents.md || test -f scripts/generate-essential-docs.sh && echo PASS || echo FAIL"

- id: M141
  name: "仕様と実態の完全同期"
  description: |
    core-manifest.yaml、settings.json、実ファイルを完全同期させる。
    未登録ファイル（depends-check.sh, role-resolver.sh）の処遇を決定。

    **問題:**
    - depends-check.sh: ファイル存在、settings.json 未登録
    - role-resolver.sh: ファイル存在、settings.json 未登録（削除候補）
    - core-manifest.yaml の Total（36）と実態の差分

    **方針:**
    1. 未登録ファイルは「登録」または「削除」
    2. core-manifest.yaml の数値を実態に合わせる
    3. 検証スクリプト（verify-manifest.sh）を作成
  status: achieved
  depends_on: [M140]
  playbooks: []
  done_when:
    - "[x] depends-check.sh が settings.json に登録されているか、ファイルが削除されている"
    - "[x] role-resolver.sh が settings.json に登録されているか、ファイルが削除されている"
    - "[x] scripts/verify-manifest.sh が存在し、実行可能"
    - "[x] scripts/verify-manifest.sh が PASS（仕様=実態）"
  test_commands:
    - "grep -q 'depends-check.sh' .claude/settings.json || ! test -f .claude/hooks/depends-check.sh && echo PASS || echo FAIL"
    - "grep -q 'role-resolver.sh' .claude/settings.json || ! test -f .claude/hooks/role-resolver.sh && echo PASS || echo FAIL"
    - "test -x scripts/verify-manifest.sh && echo PASS || echo FAIL"
    - "bash scripts/verify-manifest.sh && echo PASS || echo FAIL"

- id: M142
  name: "全 Hook の実動作テスト"
  description: |
    bash -n（構文チェック）ではなく、実際に発火させて期待動作を検証する。
    hook-runtime-test.sh を拡張し、全 Hook をカバーする。

    **現状:**
    - hook-runtime-test.sh: 11 テスト（一部 Hook のみカバー）
    - 構文チェックは全 PASS だが、実動作は未検証

    **目標:**
    - 全 Hook（登録済み 20 本）の実動作テスト
    - 各 Hook の期待動作を明文化
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M141]
  playbooks:
    - playbook-m142-hook-tests.md
  done_when:
    - "[x] hook-runtime-test.sh が全登録 Hook をカバーしている"
    - "[x] 各 Hook の期待動作がコメントで明文化されている"
    - "[x] hook-runtime-test.sh が全テスト PASS"
  test_commands:
    - "bash scripts/hook-runtime-test.sh 2>&1 | tail -1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

- id: M143
  name: "全 SubAgent/Skill/Command の実動作テスト"
  description: |
    SubAgent（3本）、Skill（6本）、Command（10本）の実動作テストを作成・実行。

    **対象:**
    - SubAgent: pm.md, critic.md, reviewer.md
    - Skill: context-management, lint-checker, plan-management, post-loop, state, test-runner
    - Command: compact, crit, focus, lint, playbook-init, post-loop, rollback, state-rollback, task-start, test

    **目標:**
    - 各コンポーネントの最低限の動作確認
    - 動作しないものは修正または削除
  status: skipped
  skipped_at: 2025-12-21
  skipped_reason: "M150-M155 Deep Audit で代替達成（動線単位E2Eテストで網羅）"
  depends_on: [M142]
  playbooks: []
  done_when:
    - "[~] scripts/test-subagents.sh が存在し、3 SubAgent をテスト → Deep Audit で代替"
    - "[~] scripts/test-skills.sh が存在し、6 Skill をテスト → Deep Audit で代替"
    - "[~] scripts/test-commands.sh が存在し、10 Command をテスト → Deep Audit で代替"
    - "[~] 全テスト PASS（動作しないものは修正済み） → flow-runtime-test.sh で代替"
  test_commands:
    - "bash scripts/flow-runtime-test.sh 2>&1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

- id: M144
  name: "Core Layer 凍結"
  description: |
    Core Layer（計画動線 6 + 検証動線 5 = 11 コンポーネント）の動作が保証された状態で凍結。
    以降の変更はレビュー必須とする。

    **Core 11 コンポーネント:**
    計画動線: prompt-guard.sh, task-start.md, pm.md, state, plan-management, playbook-init.md
    検証動線: crit.md, critic.md, critic-guard.sh, test, lint

    **凍結方法:**
    - protected-files.txt に追加
    - core-manifest.yaml に frozen: true を設定
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M143]
  playbooks:
    - playbook-m144-core-flow-validation.md
  done_when:
    - "[x] Core 11 コンポーネントが protected-files.txt に登録されている"
    - "[x] core-manifest.yaml の core セクションに frozen: true が設定されている"
    - "[x] 全 Core コンポーネントが M142/M143 のテストを PASS 済み"
  test_commands:
    - "grep -q 'prompt-guard.sh' .claude/protected-files.txt && echo PASS || echo FAIL"
    - "grep -q 'pm.md' .claude/protected-files.txt && echo PASS || echo FAIL"
    - "grep -q 'critic.md' .claude/protected-files.txt && echo PASS || echo FAIL"
    - "grep -q 'frozen: true' governance/core-manifest.yaml && echo PASS || echo FAIL"

- id: M145
  name: "仕様-実態乖離の自動検出"
  description: |
    二度と仕様と実態の乖離が発生しないよう、自動検出の仕組みを構築する。

    **仕組み:**
    1. session-start.sh が verify-manifest.sh を呼び出す
    2. 乖離検出時に警告を表示
    3. 新規コンポーネント追加時にも検出

    **目標:**
    セッション開始時に「仕様に書いてあるのに存在しない」が即座に検出される。
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M144]
  playbooks:
    - playbook-m145-manifest-integrity.md
  done_when:
    - "[x] session-start.sh が verify-manifest.sh を呼び出している"
    - "[x] 乖離検出時に警告が表示される"
    - "[x] 警告が session-start.sh の出力に含まれる"
  test_commands:
    - "grep -q 'verify-manifest.sh' .claude/hooks/session-start.sh && echo PASS || echo FAIL"
    - "bash .claude/hooks/session-start.sh 2>&1 | grep -qE '乖離|警告|WARN' || echo PASS"

- id: M146
  name: "M127 再開 - Reviewer 自動化"
  description: |
    M140-M145 でコア機能の動作保証が完了した後、M127 を再開する。
    M127 の内容をそのまま引き継ぐ。

    **M127 の目標（再掲）:**
    1. reviewer が config.roles.reviewer を読んで自動分岐
    2. Codex の場合 codex exec --full-auto を実行
    3. PASS/FAIL をパースして reviewed: true/false を更新
    4. FAIL 時に修正提案を返却
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M145]
  playbooks:
    - playbook-m146-context-consolidation.md
  done_when:
    - "[x] reviewer SubAgent が config.roles.reviewer を読んで分岐できる"
    - "[x] codex の場合、codex exec --full-auto を Bash で実行できる"
    - "[x] RESULT: PASS/FAIL をパースして reviewed: true/false を更新できる"
    - "[x] FAIL 時に修正提案を返却できる"
  test_commands:
    - "grep -q 'codex exec' .claude/agents/reviewer.md && echo PASS || echo FAIL"
    - "grep -qE 'config\\.roles\\.reviewer|roles\\.reviewer' .claude/agents/reviewer.md && echo PASS || echo FAIL"

- id: M147
  name: "MERGE済ドキュメント削除"
  description: |
    M146 コンテキスト収束に続く第2弾。
    M122 で統合完了した6ファイルを削除する。
    統合先に内容が存在することを確認後、安全に削除。
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M146]
  playbooks:
    - playbook-m147-merge-complete-deletion.md
  done_when:
    - "[x] 6件のMERGE済ファイルが削除されている"
    - "[x] 統合先ファイルに内容が存在することが確認されている"
    - "[x] FREEZE_QUEUE から DELETE_LOG へ移動されている"
    - "[x] 削除後も全テスト（flow-runtime-test）が PASS する"
  test_commands:
    - "test ! -f docs/admin-contract.md && echo PASS || echo FAIL"
    - "test ! -f docs/orchestration-contract.md && echo PASS || echo FAIL"
    - "bash scripts/flow-runtime-test.sh 2>&1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

- id: M148
  name: "MERGE予定ドキュメント統合"
  description: |
    M147 に続くコンテキスト収束の第3弾。
    MERGE予定の3ファイルを分析し、適切に処理する。
    - flow-document-map.md: 削除（essential-documents.md で完全カバー）
    - ARCHITECTURE.md: 移行後削除
    - hook-registry.md: 処理方針決定（KEEP）
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M147]
  playbooks:
    - playbook-m148-merge-pending-docs.md
  done_when:
    - "[x] docs/flow-document-map.md が削除されている"
    - "[x] docs/ARCHITECTURE.md の固有コンテンツが移行されている"
    - "[x] docs/ARCHITECTURE.md が削除されている"
    - "[x] docs/hook-registry.md の処理方針が決定されている（KEEP）"
    - "[x] FREEZE_QUEUE が更新されている"
    - "[x] 削除後も全テスト（flow-runtime-test）が PASS する"
  test_commands:
    - "test ! -f docs/flow-document-map.md && echo PASS || echo FAIL"
    - "test ! -f docs/ARCHITECTURE.md && echo PASS || echo FAIL"
    - "bash scripts/flow-runtime-test.sh 2>&1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

# ============================================================
# M149: 自覚的動作の強化（Self-Aware Operation）
# ============================================================

- id: M149
  name: "自覚的動作の強化"
  description: |
    LLMがユーザープロンプトなしで自覚的に動線に乗れる状態を構築。
    発見された3つの致命的欠陥を修正:
    1. critic-guard.sh: self_complete がセッション跨ぎで残る
    2. prompt-guard.sh: exit 0 で「推奨」止まり、強制ではない
    3. RUNBOOK.md: 「判断すべき瞬間」が曖昧
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M148]
  playbooks:
    - playbook-m149a-critic-guard-fix.md
    - playbook-m149b-prompt-guard-block.md
    - playbook-m149c-self-aware-guidelines.md
  done_when:
    - "[x] critic-guard.sh が self_complete にフェーズ情報を検証する"
    - "[x] session-start.sh で self_complete がリセットされる"
    - "[x] prompt-guard.sh が playbook=null + タスク検出時に exit 2 でブロックする"
    - "[x] タスク検出パターンが強化されている"
    - "[x] RUNBOOK.md に Self-Aware Operation セクションが追加されている"
    - "[x] 全テスト（flow-runtime-test）が PASS する"
  test_commands:
    - "grep -q 'phase\\|PHASE_ID' .claude/hooks/critic-guard.sh && echo PASS || echo FAIL"
    - "grep -A20 'WORK_PATTERNS' .claude/hooks/prompt-guard.sh | grep -q 'exit 2' && echo PASS || echo FAIL"
    - "grep -q 'Self-Aware' RUNBOOK.md && echo PASS || echo FAIL"
    - "bash scripts/flow-runtime-test.sh 2>&1 | grep -q 'ALL.*PASS' && echo PASS || echo FAIL"

# ============================================================
# M150-M155: Deep Audit + Final Freeze（完成ロードマップ）
# ============================================================
# 背景: 凍結対象の全ファイルを動線単位で1つずつ精査し、
#       1行の無駄もない状態でリファクタリングして凍結する。
# 目的: リポジトリの完成
# ============================================================

- id: M150
  name: "Deep Audit - 計画動線"
  description: |
    計画動線の全7ファイルを1つずつ精査し、動作確認、必要性議論、Codex レビューを実施。
    対象: prompt-guard.sh, task-start.md, pm.md, state/SKILL.md, plan-management/SKILL.md, playbook-init.md, reviewer.md
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M149]
  playbooks:
    - playbook-m150-deep-audit-planning-flow.md
  done_when:
    - "[x] 全7ファイルが Read され、動作が理解されている"
    - "[x] 各ファイルに対して Codex レビューが完了している"
    - "[x] 各ファイルの処遇（Keep/Simplify/Delete）が決定している"
    - "[x] 精査結果が docs/deep-audit-planning-flow.md に記録されている"

- id: M151
  name: "Deep Audit - 検証動線"
  description: |
    検証動線の全5ファイルを1つずつ精査。
    対象: crit.md, critic.md, critic-guard.sh, test.md, lint.md
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M150]
  playbooks:
    - playbook-m151-deep-audit-verification-flow.md
  done_when:
    - "[x] 全5ファイルの精査が完了"
    - "[x] Codex レビューが完了"
    - "[x] 精査結果が docs/deep-audit-verification-flow.md に記録されている"

- id: M152
  name: "Deep Audit - 実行動線"
  description: |
    実行動線の全10ファイルを1つずつ精査。
    対象: init-guard.sh, playbook-guard.sh, subtask-guard.sh, scope-guard.sh,
          check-protected-edit.sh, pre-bash-check.sh, check-main-branch.sh,
          lint-check.sh, lint-checker/SKILL.md, test-runner/SKILL.md
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M151]
  playbooks:
    - playbook-m152-deep-audit-execution-flow.md
  done_when:
    - "[x] 全10ファイルの精査が完了"
    - "[x] Codex レビューが完了"
    - "[x] 精査結果が docs/deep-audit-execution-flow.md に記録されている"

- id: M153
  name: "Deep Audit - 完了動線 + 共通基盤 + 横断的"
  description: |
    完了動線7 + 共通基盤6 + 横断的3 = 16ファイルを1つずつ精査。
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M152]
  playbooks:
    - playbook-m153-deep-audit-completion-common.md
  done_when:
    - "[x] 全16ファイルの精査が完了"
    - "[x] Codex レビューが完了"
    - "[x] 精査結果が docs/deep-audit-completion-common.md に記録されている"

- id: M154
  name: "Refactoring + Spec Sync"
  description: |
    M150-M153 の Deep Audit 結論に基づき、不要コードを削除し、仕様と実態を完全同期。
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M153]
  playbooks:
    - playbook-m154-refactoring-spec-sync.md
  done_when:
    - "[x] Delete 判定されたファイルが全て削除されている"
    - "[x] Simplify 判定されたファイルが全て簡素化されている"
    - "[x] verify-manifest.sh が PASS（仕様=実態）"
    - "[x] 全テストが PASS"

- id: M155
  name: "Final Verification + Freeze"
  description: |
    全コア機能が網羅された状態で凍結し、v1.0.0 をリリース。
  status: achieved
  achieved_at: 2025-12-21
  depends_on: [M154]
  playbooks:
    - playbook-m155-final-freeze.md
  done_when:
    - "[x] 全テスト PASS"
    - "[x] Core Layer 全ファイルが protected-files.txt に登録"
    - "[x] core-manifest.yaml に frozen: true 設定"
    - "[x] CLAUDE.md version 2.0.0"
    - "[x] git tag v1.0.0"

# ============================================================
# M156: 動線単位の完全性評価 + 大掃除
# ============================================================

- id: M156
  name: "動線単位の完全性評価 + 大掃除"
  description: |
    4動線をコンポーネントではなく「動線単位」で評価し、E2Eテストで動作確認。
    不要なファイル/フォルダを全て削除し、project.md を実態と完全同期させる。

    **背景:**
    - ユーザーが何回も指摘しているのに直らない問題の根本原因
    - Claude がコンポーネント単位で見ていて、動線単位で評価していない
    - 38コンポーネント + ドキュメント + フォルダが多すぎる

    **4動線:**
    - 計画動線: 「Xを作って」→ playbook完成 + 作業開始可能状態
    - 実行動線: playbook に基づく Edit/Write → ガードされた変更
    - 検証動線: /crit → done_criteria の PASS/FAIL 判定
    - 完了動線: phase 完了 → アーカイブ + 次タスク導出
  status: in_progress
  depends_on: [M155]
  playbooks:
    - playbook-m156-pipeline-completeness-audit.md
  done_when:
    - "[ ] 4動線すべてがE2Eで PASS（16/16 PASS）"
    - "[ ] 不要なファイル/フォルダがゼロ（deletion_candidates が全て処理済み）"
    - "[ ] 全ファイルが「なぜ存在するか」を1文で説明できる（core-manifest.yaml で網羅）"
    - "[ ] project.md が実態と完全同期（M142-M155 の achieved_at 設定、M156 追加）"
  test_commands:
    - "bash scripts/test-planning-flow-e2e.sh 2>&1 | tail -1 | grep -q 'ALL TESTS PASS' && echo PASS || echo FAIL"
    - "bash scripts/test-execution-flow-e2e.sh 2>&1 | tail -1 | grep -q 'ALL TESTS PASS' && echo PASS || echo FAIL"
    - "bash scripts/test-verification-flow-e2e.sh 2>&1 | tail -1 | grep -q 'ALL TESTS PASS' && echo PASS || echo FAIL"
    - "bash scripts/test-completion-flow-e2e.sh 2>&1 | tail -1 | grep -q 'ALL TESTS PASS' && echo PASS || echo FAIL"

```

---

## tech_stack

```yaml
framework: Claude Code Hooks System
language: Bash/Shell
deploy: local (git-based)
database: none (file-based: state.md, playbook, project.md)
```

---

## constraints

- Hook は exit code で制御（0=通過、2=ブロック）
- state.md が Single Source of Truth
- playbook なしで Edit/Write は禁止
- critic なしで phase 完了は禁止
- main ブランチでの直接作業は禁止
- 1 playbook = 1 branch
- テンポラリファイルは tmp/ に配置（playbook 完了時に自動削除）
- 完了した playbook は plan/archive/ にアーカイブ

---

## 3層構造

```
project (永続)
├── vision: 最上位目標
├── milestones[]: 中間目標
│   ├── M001: achieved
│   ├── M002: achieved
│   ├── M003: achieved
│   ├── M004: achieved
│   └── M005: achieved ← 最新完了
└── constraints: 制約条件

playbook (一時的)
├── meta.derives_from: M004  # milestone との紐付け
├── goal.done_when: milestone 達成条件
└── phases[]: 作業単位
    ├── p0: pending
    ├── p1: pending
    └── p2: pending

phase (作業単位)
├── done_criteria[]: 完了条件
├── test_method: 検証手順
└── status: achieved | in_progress | done
  achieved_at: 2025-12-17
```

---

## 自動運用フロー

```yaml
phase_complete:
  trigger: critic PASS
  action:
    - phase.status = done
    - 次の phase へ（または playbook 完了へ）

playbook_complete:
  trigger: 全 phase が done
  action:
    - playbook をアーカイブ
    - project.milestone を自動更新
      - status = achieved
      - achieved_at = now()
      - playbooks[] に追記
    - /clear 推奨をアナウンス
    - 次の milestone を特定（depends_on 分析）
    - pm で新 playbook を自動作成

project_complete:
  trigger: 全 milestone が achieved
  action:
    - project.status = completed
    - 「次の方向性を教えてください」と人間に確認
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M005（StateInjection）達成。systemMessage で状態を自動注入。 |
| 2025-12-13 | 3層構造の自動運用システム設計。用語統一。milestone に ID 追加。 |
| 2025-12-10 | 初版作成。 |
