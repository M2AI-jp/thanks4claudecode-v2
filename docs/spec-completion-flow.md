# 完了動線仕様書

> 動線を1つの連結されたユニットとして定義する。内部実装は問わない。

---

## 定義

完了動線とは、phase 完了からアーカイブ、次タスク導出までの一連の流れである。

---

## 入力

```
全 phase が完了し、critic PASS が確認された状態
```

---

## 出力

```
1. playbook が plan/archive/ に移動される
2. state.md の playbook.active が null になる
3. state.md の last_archived が更新される
4. 次の milestone が特定される（または project 完了）
5. /clear 推奨がアナウンスされる
```

---

## 成功条件

以下の全てが満たされている:

```bash
# playbook が archive に存在する
test -f plan/archive/playbook-*.md && echo OK

# playbook.active が null になっている
grep -q 'active: null' state.md && echo OK

# last_archived が更新されている
grep -q 'last_archived: plan/archive/' state.md && echo OK

# 次の milestone が案内される、または project 完了がアナウンスされる
```

---

## 失敗条件

以下のいずれかが発生した場合、動線は失敗:

| 失敗パターン | 症状 |
|-------------|------|
| アーカイブ失敗 | playbook が archive/ に移動されない |
| state 未更新 | playbook.active が active のまま |
| 次タスク導出失敗 | 次に何をすべきか不明 |
| ゴミ残留 | tmp/ に一時ファイルが残る |

---

## E2Eテストシナリオ

### シナリオ1: 正常系（playbook 完了）

```
前提: 全 phase 完了、critic PASS、self_complete=true
操作: playbook 完了処理を実行
期待:
  - playbook が archive/ に移動
  - state.md が更新される
  - 次 milestone が案内される
  - /clear 推奨がアナウンスされる
判定: archive/ に playbook が存在し、state.md が null
```

### シナリオ2: 正常系（project 完了）

```
前提: 最後の milestone の playbook が完了
操作: playbook 完了処理を実行
期待:
  - アーカイブ処理は通常通り
  - 「project 完了」がアナウンスされる
  - 次の方向性を人間に確認
判定: project.status = completed 相当のメッセージ
```

### シナリオ3: 異常系（critic 未完了）

```
前提: phase 完了だが critic PASS していない
操作: 完了処理を試みる
期待:
  - 完了処理がブロックされる
  - critic 実行を促される
判定: アーカイブされない
```

---

## 備考

この動線が動かない場合、playbook が放置されて次のタスクに進めない。または同じ playbook で作業が続いてしまい、スコープクリープが発生する。
