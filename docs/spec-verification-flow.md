# 検証動線仕様書

> 動線を1つの連結されたユニットとして定義する。内部実装は問わない。

---

## 定義

検証動線とは、/crit コマンドから done_criteria の検証が行われ、PASS/FAIL が判定されるまでの一連の流れである。

---

## 入力

```
ユーザーまたは Claude が /crit コマンドを実行する
```

---

## 出力

```
1. done_criteria が1つずつ検証される
2. 各条件に対して PASS または FAIL が判定される
3. 全条件 PASS の場合: self_complete = true に更新される
4. 1つでも FAIL の場合: 失敗理由が報告される
```

---

## 成功条件

以下の全てが満たされている:

```bash
# /crit 実行後に検証結果が表示される
# (critic SubAgent が呼び出される)

# 全条件 PASS 時に self_complete が true になる
grep -q 'self_complete: true' state.md && echo OK

# FAIL 時に具体的な理由が報告される
# (失敗理由が含まれる出力)
```

---

## 失敗条件

以下のいずれかが発生した場合、動線は失敗:

| 失敗パターン | 症状 |
|-------------|------|
| critic 未呼出 | /crit しても何も起きない |
| 検証スキップ | done_criteria を見ずに PASS と言う |
| 誤判定 | 条件を満たしていないのに PASS |
| state 未更新 | PASS なのに self_complete が false のまま |

---

## E2Eテストシナリオ

### シナリオ1: 正常系（全条件達成）

```
前提: playbook の done_criteria が全て達成された状態
操作: /crit を実行
期待:
  - 各条件が検証される
  - 全て PASS と判定される
  - self_complete = true に更新される
判定: state.md の self_complete が true
```

### シナリオ2: 正常系（一部未達成）

```
前提: playbook の done_criteria が一部未達成
操作: /crit を実行
期待:
  - 各条件が検証される
  - 未達成条件が FAIL と判定される
  - 失敗理由が報告される
  - self_complete は false のまま
判定: 具体的な失敗理由が表示される
```

### シナリオ3: 異常系（playbook なし）

```
前提: playbook=null
操作: /crit を実行
期待:
  - エラーメッセージが表示される
  - playbook 作成を促される
判定: 検証は実行されない
```

---

## 備考

この動線が動かない場合、報酬詐欺（実際には完了していないのに完了と言う）が可能になる。critic が機能しないと品質保証ができない。
