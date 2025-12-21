# 計画動線仕様書

> 動線を1つの連結されたユニットとして定義する。内部実装は問わない。

---

## 定義

計画動線とは、ユーザーのタスク要求から playbook が完成し作業開始可能な状態になるまでの一連の流れである。

---

## 入力

```
ユーザーが「Xを作って」「Yを実装して」「Zを修正して」等のタスク要求を送信する
```

---

## 出力

```
1. playbook ファイルが plan/ に存在する
2. state.md の playbook.active が null でない
3. 作業用ブランチが作成されている（main でない）
4. state.md の goal.milestone が設定されている
```

---

## 成功条件

以下の全てが満たされている:

```bash
# playbook が存在する
test -f "$(grep 'active:' state.md | awk '{print $2}')" && echo OK

# playbook.active が null でない
! grep -q 'active: null' state.md && echo OK

# 現在のブランチが main でない
[ "$(git branch --show-current)" != "main" ] && echo OK

# goal.milestone が設定されている
grep -q 'milestone: M' state.md && echo OK
```

---

## 失敗条件

以下のいずれかが発生した場合、動線は失敗:

| 失敗パターン | 症状 |
|-------------|------|
| タスク検出失敗 | ユーザーが要求したのに何も起きない |
| pm 未呼出 | playbook が作成されない |
| state.md 未更新 | playbook.active が null のまま |
| ブランチ未作成 | main ブランチのまま作業開始 |

---

## E2Eテストシナリオ

### シナリオ1: 正常系

```
前提: playbook=null, branch=main
操作: 「テスト機能を作って」と送信
期待:
  - playbook-*.md が作成される
  - state.md が更新される
  - feat/* ブランチが作成される
判定: 成功条件の4項目全てがOK
```

### シナリオ2: 異常系（タスク検出漏れ）

```
前提: playbook=null, branch=main
操作: 曖昧な文言（「ちょっと見て」等）を送信
期待:
  - 計画動線が発動しない（正常）
  - または、タスクか確認される
判定: 意図しない playbook 作成が起きない
```

### シナリオ3: 異常系（既存 playbook あり）

```
前提: playbook=active, branch=feat/*
操作: 新しいタスク要求を送信
期待:
  - 既存 playbook 完了を促される
  - または interrupt モードで処理される
判定: 既存作業が破壊されない
```

---

## 備考

この動線が動かない場合、全ての作業が開始できない。最も重要な動線。
